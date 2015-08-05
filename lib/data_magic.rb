require 'elasticsearch'
require 'safe_yaml'
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

SafeYAML::OPTIONS[:default_mode] = :safe

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
  DEFAULT_EXTENSIONS = ['.csv']
  DEFAULT_PATH = './sample-data'
  class InvalidData < StandardError
  end

  def self.s3
    if @s3.nil?
      if ENV['VCAP_APPLICATION']
        s3cred = ::CF::App::Credentials.find_by_service_name('bservice')
      else
        s3cred = {'access_key'=>  ENV['s3_access_key'], 'secret_key' => ENV['s3_secret_key']}
      end
      logger.info "s3cred = #{s3cred.inspect}"
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
    options[:fields] ||= []
    fields = options[:fields].map { |field| field.to_s }
    index_name = index_name_from_options(options)
    logger.info "search terms:#{terms.inspect}"
    squery = Stretchy.query

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

    squery = squery.where(terms) unless terms.empty?

    modified_query = squery.to_search

    #this block of code will introduce a
    #'minimum_should_match' parameter to each query
    #in order to control query precision

    unless modified_query[:match].nil?
      modified_query[:match].each do |key, value|
        modified_query[:match][key]["minimum_should_match"] = "2"
      end
    end

    full_query = {
      index: index_name,
      type: 'document',
      body: {
        from: page,
        size: per_page,
        query: modified_query
      }
    }
    if not fields.empty?
      full_query[:body][:fields] = fields
    end

    logger.info "===========> full_query:#{full_query.inspect}"
    result = client.search full_query
    logger.info "result: #{result.inspect}"
    hits = result["hits"]
    total = hits["total"]
    results = []
    if fields.empty?
      # we're getting the whole document and we can find in _source
      results = hits["hits"].map {|hit| hit["_source"]}
    else
      # we're getting a subset of fields...
      results = hits["hits"].map do |hit|
        found = hit["fields"]
        # each result looks like this:
        # {"city"=>["Springfield"], "address"=>["742 Evergreen Terrace"]}

        found.keys.each { |key| found[key] = found[key][0] }
        # now it should look like this:
        # {"city"=>"Springfield", "address"=>"742 Evergreen Terrace
        found
      end
    end

    # assemble a simpler json document to return
    {
      "total" => total,
      "page" => page,
      "per_page" => per_page,
      "results" => 	results
    }
  end

  private
    def self.create_index(es_index_name = nil, field_types={})
      es_index_name ||= self.config.scoped_index_name
      field_types['location'] = 'geo_point'
      es_types = {}
      field_types.each do |key, type|
        es_types[key] = { type: type }
      end
      begin
        client.indices.create index: es_index_name, body: {
          mappings: {
            document: {    # type 'document' is always used for external indexed docs
              properties: es_types
            }
          }
        }
        logger.info "====> index created with es type mapping: #{es_types.inspect[0..255]}"
      rescue Elasticsearch::Transport::Transport::Errors::BadRequest => error
        logger.debug "create_index attempt failed #{es_index_name} -- maybe it already exists"
        logger.error error.to_s
      end
      es_index_name
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
