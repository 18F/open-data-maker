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
require_relative 'data_magic/query_builder'
require_relative 'data_magic/error_checker'
require_relative 'zipcode/zipcode'

SafeYAML::OPTIONS[:default_mode] = :safe

class IndifferentHash < Hash
  include Hashie::Extensions::MergeInitializer
  include Hashie::Extensions::IndifferentAccess
end

module DataMagic
  class << self
    attr_accessor :config
    def logger
      Config.logger
    end
  end

  DEFAULT_PAGE_SIZE = 20
  MAX_PAGE_SIZE = 100
  DEFAULT_EXTENSIONS = ['.csv']
  DEFAULT_PATH = './sample-data'
  class InvalidData < StandardError
  end
  class InvalidDictionary < StandardError
  end

  def self.s3
    if @s3.nil?
      if ENV['VCAP_APPLICATION']
        s3cred = ::CF::App::Credentials.find_by_service_name(ENV['s3_bucket_service'] || 'bservice')
      else
        s3cred = {'access_key'=>  ENV['s3_access_key'], 'secret_key' => ENV['s3_secret_key']}
      end
      logger.info "s3cred = #{s3cred.inspect}"
      if ENV['RACK_ENV'] != 'test'
        ::Aws.config[:credentials] = ::Aws::Credentials.new(s3cred['access_key'], s3cred['secret_key'])
      end
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
    errors = ErrorChecker.check(terms, options, config)
    return { errors: errors } if errors.length > 0

    query_body = QueryBuilder.from_params(terms, options, config)
    index_name = index_name_from_options(options)
    logger.info "search terms:#{terms.inspect}"

    full_query = {
      index: index_name,
      type: 'document',
      body: query_body
    }

    # Per https://www.elastic.co/guide/en/elasticsearch/reference/current/search-request-body.html:
    # "the search_type and the query_cache must be passed as query-string parameters"
    if options[:command] == 'stats'
      full_query.merge! :search_type => 'count'
    end

    logger.info "FULL_QUERY: #{full_query.inspect}"

    time_start = Time.now.to_f
    result = client.search full_query

    search_time = Time.now.to_f - time_start
    logger.info "ES query time (ms): #{result["took"]} ; Query fetch time (s): #{search_time} ; result: #{result.inspect[0..500]}"

    hits = result["hits"]
    total = hits["total"]
    results = []
    unless query_body.has_key? :fields
      # we're getting the whole document and we can find in _source
      results = hits["hits"].map {|hit| hit["_source"]}
    else
      # we're getting a subset of fields...
      results = hits["hits"].map do |hit|
        found = hit.fetch("fields", {})
        # each result looks like this:
        # {"city"=>["Springfield"], "address"=>["742 Evergreen Terrace"]}

        found.keys.each { |key| found[key] = found[key][0] }
        # now it should look like this:
        # {"city"=>"Springfield", "address"=>"742 Evergreen Terrace}

        # re-insert null fields that didn't get returned by ES
        query_body[:fields].each do |field|
          if !found.has_key?(field)
            found[field] = nil
          end
        end
        found
      end
    end

    metadata = {
      "total" => total,
      "page" => query_body[:from] / query_body[:size],
      "per_page" => query_body[:size]
    }
    if options[:debug]
      metadata["search_time"] = search_time
      metadata["ES_took_ms"] = result["took"]
    end

    # assemble a simpler json document to return
    simple_result =
    {
      "metadata" => metadata,
      "results" => 	results
    }

    if options[:command] == 'stats'
      # Remove metrics that weren't requested.
      aggregations = result['aggregations'] || {}
      aggregations.each do |f_name, values|
        if options[:metrics] && options[:metrics].size > 0
          aggregations[f_name] = values.reject { |k, v| !(options[:metrics].include? k) }
        else
          # Keep everything is no metric list is provided
          aggregations[f_name] = values
        end
      end

      simple_result.merge!({"aggregations" => aggregations})
    end

    simple_result
  end

  private

  def self.nested_object_type(hash)
    hash.each do |key, value|
      if value.is_a?(Hash) && value[:type].nil?  # things are nested under this
        hash[key] = {
          path: "full", type: "object",
          properties: value
        }
        nested_object_type(value)
      end
    end
  end

  def self.create_index(es_index_name = nil, field_types={})
    logger.info "create_index field_types: #{field_types.inspect[0..500]}"
    es_index_name ||= self.config.scoped_index_name
    field_types['location'] = 'lat_lon' # custom lat_lon type maps to geo_point with additional field options
    es_types = NestedHash.new.add(es_field_types(field_types))
    nested_object_type(es_types)
    begin
      logger.info "====> creating index with type mapping: #{es_types.inspect[0..500]}"
      client.indices.create base_index_hash(es_index_name, es_types)
    rescue Elasticsearch::Transport::Transport::Errors::BadRequest => error
      if error.message.include? "IndexAlreadyExistsException"
        logger.debug "create_index failed: #{es_index_name} already exists"
      else
        logger.error error.to_s
        raise error
      end
    end
    es_index_name
  end

  def self.base_index_hash(es_index_name, es_types)
    {
      index: es_index_name,
      body: {
        settings: {
          analysis: {
            filter: {
              autocomplete_filter: {
                  type: 'edge_ngram',
                  min_gram: 3,
                  max_gram: 25
              }
            },
            analyzer: {
              autocomplete_index: {
                tokenizer: 'standard',
                filter: ['lowercase', 'stop', 'autocomplete_filter'],
                type: 'custom'
              },
              autocomplete_search: {
                tokenizer: 'standard',
                filter: ['lowercase', 'stop'],
                type: 'custom'
              }
            }
          }
        },
        mappings: {
          document: { # type 'document' is always used for external indexed docs
            properties: es_types
          }
        }
      }
    }
  end

  # convert the types from data.yaml to Elasticsearch-specific types
  def self.es_field_types(field_types)
    custom_type = {
      'literal' => {type: 'string', index:'not_analyzed'},
      'name' => {type: 'string', index:'not_analyzed'},
      'lowercase_name' => {type: 'string', index:'not_analyzed', store: false},
      'autocomplete' => { type: 'string',
                          index_analyzer: 'autocomplete_index',
                          search_analyzer: 'autocomplete_search'
      },
      'lat_lon' => { type: 'geo_point',
                     lat_lon: true,
                     store: true

      }
   }
    field_types.each_with_object({}) do |(key, type), result|
      result[key] = custom_type[type]
      result[key] ||= { type: type }
    end
  end


  # get the real index name when given either
  # endpoint: api endpoint configured in data.yaml
  # index: index name
  def self.index_name_from_options(options)
    api = options[:endpoint]
    options[:index] = options['index'].to_sym if options['index']
    logger.info "WARNING: DataMagic.search options api will override index, only one expected"  if api and options[:index]
    if api
      index_name = config.find_index_for(api)
      if index_name.nil?
        raise ArgumentError, "no configuration found for '#{api}', available endpoints: #{self.config.api_endpoint_names.inspect}"
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
        end
      end
    end
  end

  def self.reindex
    logger.info "reindex"
    if @index_thread and @index_thread.alive?
      logger.info "kill off old indexing process"
      Thread.kill(@index_thread)
      @index_thread = nil
    end

    logger.info "DELETE the index and RELOAD config..."
    config.delete_index_and_reload_config  # refresh the config
    @index_thread = Thread.new do
      logger.info "re-indexing!"
      self.index_with_dictionary
    end
  end


  def self.eservice_uri
    if @eservice_uri.nil?
      eservice = ::CF::App::Credentials.find_by_service_name(ENV['es_service'] || 'eservice')
      logger.info "eservice: #{eservice.inspect}"
      fail "Please set up eservice credentials in Cloud Foundry env" if eservice.nil?
      @eservice_uri = eservice['url'] || eservice['uri']
    end
    @eservice_uri
  end

  def self.client
    opts =
    {
      transport_options: {
        request: {
          timeout: 5*60,
          open_timeout: 5*60
        }
      }
    }
    if ENV['ES_DEBUG']
      tracer = Logger.new(STDOUT)
      tracer.formatter = ->(_s, _d, _p, m) { "#{m.gsub(/^.*$/) { |n| '   ' + n }}\n" }
      opts[:tracer] = tracer
    end
    if @client.nil?
      if ENV['VCAP_APPLICATION']    # Cloud Foundry
        logger.info "connect to Cloud Foundry elasticsearch service"
        logger.info "eservice_uri: #{eservice_uri}"
        opts[:host] = eservice_uri
      end
      logger.info "default local elasticsearch connection"
      @client = ::Elasticsearch::Client.new(opts)
      Stretchy.configure do |c|
        c.client = @client   # use a custom client
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
  def self.init(options = {})
    logger.info "--"*20
    logger.info "    DataMagic init VCAP_APPLICATION=#{ENV['VCAP_APPLICATION'].inspect}"
    logger.info "--"*20
    logger.info "options: #{options.inspect}"
    logger.info "self.config: #{self.config.inspect}"
    if self.config.nil?   # only init once
      ::Aws.eager_autoload!       # see https://github.com/aws/aws-sdk-ruby/issues/833
      self.config = Config.new(s3: self.s3)    # loads data.yaml
      self.client   # make sure we can set up the Elasticsearch client
      self.index_data_if_needed unless options[:load_now] == false
      @index_thread.join if options[:load_now] and @index_thread
    end
  end # init

  # DANGER!
  # removes all indices associated with the loaded data.yaml
  def self.destroy
    logger.info "DataMagic.destroy"
    @index_thread.join unless @index_thread.nil?   # finish up indexing, if needed
    self.config.clear_all unless config.nil?
    self.config = nil
  end
end
