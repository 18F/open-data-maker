require 'elasticsearch'
require 'yaml'
require 'csv'
require 'stretchy'
require 'hashie'
require './lib/nested_hash'
require 'aws-sdk'
require 'uri'
require 'data_magic/config'
require 'data_magic/index'

module DataMagic
  extend DataMagic::Config
  extend DataMagic::Index

  class << self
    attr_accessor :client
  end

  class IndifferentHash < Hash
    include Hashie::Extensions::MergeInitializer
    include Hashie::Extensions::IndifferentAccess
  end


  DEFAULT_PATH = './sample-data'
  class InvalidData < StandardError
  end

  Config.init

  def self.s3
    if @s3.nil?
      if ENV['VCAP_APPLICATION']
        s3cred = CF::App::Credentials.find_by_service_name('s3-sb-ed-college-choice')
      else
        s3cred = {'access_key'=>  ENV['s3_access_key'], 'secret_key' => ENV['s3_secret_key']}
        puts "s3cred = #{s3cred.inspect}"
      end
      Aws.config[:credentials] = Aws::Credentials.new(s3cred['access_key'], s3cred['secret_key'])
      Aws.config[:region] = 'us-east-1'
      @s3 = Aws::S3::Client.new
      puts "@s3 = #{@s3.inspect}"
    end
    @s3
  #  puts "response: #{response.inspect}"
  end


  #========================================================================
  #   Public Class Methods
  #========================================================================

  def self.delete_all
    client.indices.delete index: '_all'
    client.indices.clear_cache
    Config.init
  end

  def self.scoped_index_name(index_name)
    Config.load_if_needed
    env = ENV['RACK_ENV']
    "#{env}-#{index_name}"
  end

  def self.delete_index(index_name)
    Config.load_if_needed
    index_name = scoped_index_name(index_name)
    client.indices.delete index: index_name
    client.indices.clear_cache
    # TODO: remove some entries from @@files
  end

  # thin layer on elasticsearch query
  def self.search(terms, options = {})
    terms = IndifferentHash.new(terms)
    Config.load_if_needed
    index_name = index_name_from_options(options)
    # puts "===========> search terms:#{terms.inspect}"
    squery = Stretchy.query(type: 'document')

    distance = terms[:distance]
    if distance && !distance.empty?
      location = { lat: 37.615223, lon:-122.389977 } #sfo
      squery = squery.geo('location', distance: distance, lat: location[:lat], lng: location[:lon])
      terms.delete(:distance)
      terms.delete(:zip)
    end

    page = terms[:page] || 0
    per_page = terms[:per_page] || Config.page_size

    terms.delete(:page)
    terms.delete(:per_page)

    # puts "--> terms: #{terms.inspect}"
    squery = squery.where(terms) unless terms.empty?

    full_query = {index: index_name, body: {
        from: page,
        size: per_page,
        query: squery.to_search
      }
    }

    puts "===========> full_query:#{full_query.inspect}"

    result = client.search full_query
    puts "result: #{result.inspect}"
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
def self.create_index(scoped_index_name)
  client.indices.create index: scoped_index_name, body: {
    mappings: {
      document: {    # for now type 'document' is always used
        properties: {
         location: { type: 'geo_point' }
        }
      }
    }
  }
end

# takes a external index name, returns scoped index name
def self.create_index_if_needed(external_index_name)
  index_name = scoped_index_name(external_index_name)
  puts "index:#{index_name}"
  unless client.indices.exists? index: index_name
    create_index index_name
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
  puts "WARNING: DataMagic.search options api will override index, only one expected"  if options[:api] and options[:index]
  if options[:api]
    index_name = Config.find_index_for(options[:api])
    if index_name.nil?
      raise ArgumentError, "no configuration found for '#{options[:api]}', available endpoints: #{api_endpoint_names.inspect}"
    end
  else
    index_name = options[:index]
  end
  index_name = scoped_index_name(index_name)
end


def self.index_data_if_needed
  directory_path = DataMagic.data_path
  index = load_config(directory_path)
  if Config.new?(index)
    puts "new config detected... hitting the big RESET button"
    Thread.new do
      self.delete_all
      puts "deleted all indices, re-indexing..."
      self.import_all
    end
    puts "indexing on a thread"
  end
end



puts "--"*40
puts "    DataMagic init VCAP_APPLICATION=#{ENV['VCAP_APPLICATION'].inspect}"
puts "--"*40

Aws.eager_autoload!       # see https://github.com/aws/aws-sdk-ruby/issues/833

if ENV['VCAP_APPLICATION']
  # Cloud Foundry
  puts "connect to Cloud Foundry elasticsearch service"
  require 'cf-app-utils'
  eservice = CF::App::Credentials.find_by_service_name('eservice')
  puts "eservice: #{eservice.inspect}"
  service_uri = eservice['url']
  puts "service_uri: #{service_uri}"
  self.client = Elasticsearch::Client.new host: service_uri  #, log: true
  self.index_data_if_needed
else
  puts "default elasticsearch connection"
  self.client = Elasticsearch::Client.new #log: true
end

end
