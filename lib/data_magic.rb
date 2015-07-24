require 'elasticsearch'
require 'yaml'
require 'csv'
require 'stretchy'
require 'hashie'
require './lib/nested_hash'
require 'aws-sdk'
require 'uri'
require 'cf-app-utils'
require 'logger'

require_relative 'data_magic/config'
require_relative 'data_magic/index'

module DataMagic

  class << self
    attr_accessor :config
    def logger
      Config.logger
    end
  end

  class IndifferentHash < Hash
    include Hashie::Extensions::MergeInitializer
    include Hashie::Extensions::IndifferentAccess
  end

  DEFAULT_PAGE_SIZE = 20
  DEFAULT_PATH = './sample-data'
  class InvalidData < StandardError
  end

  def self.s3
    if @s3.nil?
      if ENV['VCAP_APPLICATION']
        s3cred = ::CF::App::Credentials.find_by_service_name('bservice')
      else
        s3cred = {'access_key'=>  ENV['s3_access_key'], 'secret_key' => ENV['s3_secret_key']}
        logger.info "s3cred = #{s3cred.inspect}"
      end
      ::Aws.config[:credentials] = ::Aws::Credentials.new(s3cred['access_key'], s3cred['secret_key'])
      ::Aws.config[:region] = 'us-east-1'
      @s3 = ::Aws::S3::Client.new
      logger.info "@s3 = #{@s3.inspect}"
    end
    @s3
  #  logger.info "response: #{response.inspect}"
  end


  #========================================================================
  #   Public Class Methods
  #========================================================================

  # thin layer on elasticsearch query
  def self.search(terms, options = {})
    terms = IndifferentHash.new(terms)
    index_name = index_name_from_options(options)
    logger.info "search terms:#{terms.inspect}"
    squery = Stretchy.query(type: 'document')

    distance = terms[:distance]
    if distance && !distance.empty?
      location = { lat: 37.615223, lon:-122.389977 } #sfo
      squery = squery.geo('location', distance: distance, lat: location[:lat], lng: location[:lon])
      terms.delete(:distance)
      terms.delete(:zip)
    end

    page = terms[:page] || 0
    per_page = terms[:per_page] || config.page_size

    terms.delete(:page)
    terms.delete(:per_page)

    # logger.info "--> terms: #{terms.inspect}"
    # binding.pry
    squery = squery.where(terms) unless terms.empty?

    full_query = {index: index_name, body: {
        from: page,
        size: per_page,
        query: squery.to_search
      }
    }

    logger.info "===========> full_query:#{full_query.inspect}"

    result = client.search full_query
    logger.info "result: #{result.inspect}"
    hits = result["hits"]
    total = hits["total"]
    hits["hits"].map {|hit| hit["_source"]}
    results = hits["hits"].map {|hit| hit["_source"]}
    {
      "total" => total,
      "page" => page,
      "per_page" => per_page,
      "results" => 	results
    }
  end

  private
    def self.create_index(es_index_name, field_types={})
      field_types = field_types.merge({
       location: { type: 'geo_point' }
      })
      logger.info "create_index #{es_index_name} #{field_types}"
      client.indices.create index: es_index_name, body: {
        mappings: {
          document: {    # for now type 'document' is always used
            properties: field_types
          }
        }
      }
    end

    # takes a external index name, returns scoped index name
    def self.create_index_if_needed(es_index_name = nil)
      index_name = es_index_name || self.config.scoped_index_name
      unless client.indices.exists?(index: index_name)
        logger.info "creating index: #{index_name}"
        create_index(index_name)
      end
      index_name
    end

    # row: a hash  (keys may be strings or symbols)
    # new_fields: hash current_name : new_name
    # returns a hash (which may be a subset of row) where keys are new_name
    #         with value of corresponding row[current_name]
    def self.map_field_names(row, new_fields)
      mapped = {}
      row.each do |key, value|
        new_key = new_fields[key.to_sym] || new_fields[key.to_s]
        if new_key
          value = value.to_f if new_key.include? "location"
          mapped[new_key] = value
        end
      end
      mapped
    end

    # get the real index name when given either
    # api: api endpoint configured in data.yaml
    # index: index name
    def self.index_name_from_options(options)
      options[:api] = options['api'].to_sym if options['api']
      options[:index] = options['index'].to_sym if options['index']
      logger.info "WARNING: DataMagic.search options api will override index, only one expected"  if options[:api] and options[:index]
      if options[:api]
        index_name = config.find_index_for(options[:api])
        if index_name.nil?
          raise ArgumentError, "no configuration found for '#{options[:api]}', available endpoints: #{self.config.api_endpoint_names.inspect}"
        end
      else
        index_name = options[:index]
      end
      index_name = self.config.scoped_index_name(index_name)
    end

    def self.index_data_if_needed
      logger.info "index_data_if_needed"
      if @index_thread and @index_thread.alive?
        logger.info "already indexing... skip!"
      else
        if config.update_indexed_config
          logger.info "new config detected... hitting the big RESET button"
          @index_thread = Thread.new do
            logger.info "re-indexing..."

            self.import_with_dictionary
            logger.info "indexing on a thread"
          end
        end
      end
    end

    def DataMagic.client
      if @client.nil?
        if ENV['VCAP_APPLICATION']    # Cloud Foundry
          logger.info "connect to Cloud Foundry elasticsearch service"
          eservice = ::CF::App::Credentials.find_by_service_name('eservice')
          logger.info "eservice: #{eservice.inspect}"
          service_uri = eservice['url'] || eservice['uri']
          logger.info "service_uri: #{service_uri}"
          @client = ::Elasticsearch::Client.new host: service_uri  #, log: true
          Stretchy.configure do |c|
            c.client     = @client                       # use a custom client
          end
        else
          logger.info "default local elasticsearch connection"
          @client = ::Elasticsearch::Client.new #log: true
        end
      end
      @client
    end

    # call this before calling anything that requires data.yaml
    # this will load data.yaml, and optionally index referenced data
    # options hash
    #   load_now: default load in background,
    #             false don't load,
    #             true load immediately, wait for complete indexing
    def DataMagic.init(options = {})
      logger.info "--"*20
      logger.info "    DataMagic init VCAP_APPLICATION=#{ENV['VCAP_APPLICATION'].inspect}"
      logger.info "--"*20
      logger.info "options: #{options.inspect}"
      logger.info "self.config: #{self.config.inspect}"
      if self.config.nil?   # only init once
        ::Aws.eager_autoload!       # see https://github.com/aws/aws-sdk-ruby/issues/833
        self.config = Config.new(s3: self.s3)    # loads data.yaml
        self.index_data_if_needed unless options[:load_now] == false
        @index_thread.join if options[:load_now] and @index_thread
      end
    end # init

    # this is only used for testing
    # it will clean up all indices associated with the loaded data.yaml
    def DataMagic.destroy
      logger.info "DataMagic.destroy"
      @index_thread.join unless @index_thread.nil?   # finish up indexing, if needed
      self.config.clear_all unless config.nil?
      self.config = nil
    end

end # DataMagic
