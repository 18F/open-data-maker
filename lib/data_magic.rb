

class DataMagic
  DEFAULT_PATH = './sample-data'
  class InvalidData < StandardError
  end

  require 'elasticsearch'
  require 'yaml'
  require 'csv'

  puts "--"*40
  puts "    DataMagic init VCAP_APPLICATION=#{ENV['VCAP_APPLICATION'].inspect}"
  puts "--"*40
  if ENV['VCAP_APPLICATION']
    # Cloud Foundry
    puts "connect to Cloud Foundry elasticsearch service"
    require 'cf-app-utils'
    eservice = CF::App::Credentials.find_by_service_name('eservice')
    puts "eservice: #{eservice.inspect}"
    service_uri = eservice['url']
    puts "service_uri: #{service_uri}"
    @@client = Elasticsearch::Client.new host: service_uri, log: true
  else
    puts "default elasticsearch connection"
    @@client = Elasticsearch::Client.new #log: true
  end

  @@files = []
  @@mapping = {}
  @@api_endpoints = {}


  #========================================================================
  #    Setup
  #========================================================================

  def self.client
    @@client
  end

  def self.files
    @@files
  end

  def self.mapping
    @@mapping
  end

  def self.data_path
    ENV['DATA_PATH'] || DEFAULT_PATH
  end

  def self.load_config(directory_path = data_path)
    puts "load config #{directory_path.inspect}"
    @@files = Dir.glob("#{directory_path}/**/*.csv").select { |entry| File.file? entry }
    config = YAML.load_file("#{directory_path}/data.yaml")
    index = config['index'] || 'general'
    mapping[index] = config['files']
    files.each do |filepath|
      fname = filepath.split('/').last
      file_config = mapping[index][fname] ||= {}  # initialize to empty hash if not given
      endpoint = file_config['api'] || 'data'
      @@api_endpoints[endpoint] = {index: index}
    end
    index
  end

  def self.init_config
    @@files = []
    @@mapping = {}
    @@api_endpoints = {}
  end

  self.init_config

  #========================================================================
  #   Public Class Methods
  #========================================================================

  def self.delete_all
    client.indices.delete index: '_all'
    client.indices.clear_cache
    init_config
  end


  def self.find_index_for(api)
    load_config_if_needed
    @@api_endpoints[api][:index]
  end

  # returns an array of api_endpoints
  # list of strings
  def self.api_endpoint_names
    load_config_if_needed
    @@api_endpoints.keys
  end

  def self.scoped_index_name(index_name)
    load_config_if_needed
    env = ENV['RACK_ENV']
    "#{env}-#{index_name}"
  end

  def self.delete_index(index_name)
    load_config_if_needed
    index_name = scoped_index_name(index_name)
    client.indices.delete index: index_name
    client.indices.clear_cache
    # TODO: remove some entries from @@files
  end

  def self.import_csv(index_name, datafile, options={})
    load_config_if_needed
    unless datafile.respond_to?(:read)
      raise ArgumentError, "can't read datafile #{datafile.inspect}"
    end
    index_name = scoped_index_name(index_name)
    data = datafile.read

    if options[:force_utf8]
      data = data.encode('UTF-8', invalid: :replace, replace: '')
    end

    fields = nil
    new_fields = options[:fields]
    num_rows = 0
    begin
      CSV.parse(data, headers:true, :header_converters=> lambda {|f| f.strip.to_sym }) do |row|
        fields ||= row.headers
        row = row.to_hash
        if new_fields
          mapped = {}
          row.each do |key, value|
            new_key = new_fields[key.to_sym] || new_fields[key.to_s]
            mapped[new_key] = value if new_key
          end
          row = mapped
        end
        client.index index:index_name, type:'document', body: row
        num_rows += 1
      end
    rescue Exception => e
      puts "row #{num_rows}: #{e.message}"
    end

    raise InvalidData, "invalid file format or zero rows" if num_rows == 0

    fields = new_fields.values if new_fields
    client.indices.refresh index: index_name if num_rows > 0

    return [num_rows, fields ]
  end

  def self.import_all(directory_path, options = {})
    index = load_config(directory_path)
    files.each do |filepath|
      fname = filepath.split('/').last
      file_config = mapping[index][fname]
      #puts "indexing #{fname} config:#{file_config}"
      options[:fields] = file_config['fields']
      begin
        puts "reading #{filepath}"
        File.open(filepath) do |file|
          #puts "index: #{index}"
          rows, fields = DataMagic.import_csv(index, file, options)
          puts "imported #{rows} rows"
        end
      rescue Exception => e
        puts "Error: skipping #{filepath}, #{e.message}"
      end
    end
  end


  # thin layer on elasticsearch query
  def self.search(query, options = {})
    load_config_if_needed
    index_name = index_name_from_options(options)
    full_query = {index: index_name, body: query}
    result = client.search full_query
    hits = result["hits"]
    hits["hits"].map {|hit| hit["_source"]}
  end

private
# get the real index name when given either
# api: api endpoint configured in data.yaml
# index: index name
def self.index_name_from_options(options)
  options[:api] = options['api'].to_sym if options['api']
  options[:index] = options['index'].to_sym if options['index']
  puts "WARNING: DataMagic.search options api will override index, only one expected"  if options[:api] and options[:index]
  if options[:api]
    index_name = find_index_for(options[:api])
    if index_name.nil?
      raise ArgumentError, "no configuration found for '#{options[:api]}', available endpoints: #{api_endpoint_names.inspect}"
    end
  else
    index_name = options[:index]
  end
  index_name = scoped_index_name(index_name)
end

def self.needs_loading?
  @@files.empty?
end

def self.load_config_if_needed
  load_config if needs_loading?
end


end
