require_relative '../data_magic.rb'

module DataMagic
  require_relative 'example.rb'
  class Config
    attr_reader :data_path, :data, :dictionary, :files, :file_config, :s3, :api_endpoints
    attr_accessor :page_size

    def initialize(options = {})
      @api_endpoints = {}
      @files = []
      @dictionary = {}
      @page_size = DataMagic::DEFAULT_PAGE_SIZE
      @extensions = DataMagic::DEFAULT_EXTENSIONS
      @s3 = options[:s3]

      @data_path = options[:data_path] || ENV['DATA_PATH']
      if @data_path.nil? or @data_path.empty?
        @data_path = DEFAULT_PATH
      end
      if options[:load_datayaml] == false
        @data = {}
      else
        load_datayaml
      end
    end

    def examples
      if @examples.nil?
        api = api_endpoint_names[0]
        data['examples'] ||= []
        @examples = data['examples'].map do |i|
          Example.new(i.merge(endpoint: api))
        end
      end
      @examples
    end

    def self.init(s3 = nil)
      logger.info "Config.init #{s3.inspect}"
      @s3 = s3
      Config.load
    end

    def clear_all
      unless @data.nil? or @data.empty?
        logger.info "Config.clear_all: deleting index '#{scoped_index_name}'"
        Stretchy.delete scoped_index_name
        DataMagic.client.indices.clear_cache
      end
    end

    def self.logger=(new_logger)
      @logger = new_logger
    end

    def self.logger
      @logger ||= Logger.new("log/#{ENV['RACK_ENV'] || 'development'}.log")
    end

    def logger
      Config.logger
    end

    # fetches file configuration
    # add: whatever
    def additional_data_for_file(index)
      @data.fetch('files', []).fetch(index, {}).fetch('add', nil)
    end

    def info_for_file(index, field)
      field = field.to_s
      result = @data.fetch('files', []).fetch(index, {}).fetch(field, nil)
      result = IndifferentHash.new(result) if result.is_a? Hash
      result
    end

    def scoped_index_name(index_name = nil)
      index_name ||= @data['index']
      env = ENV['RACK_ENV']
      "#{env}-#{index_name}"
    end

    # returns an array of api_endpoints
    # list of strings
    def api_endpoint_names
      @api_endpoints.keys
    end


    def find_index_for(api)
      api_info = @api_endpoints[api] || {}
      api_info[:index]
    end

    def dictionary=(yaml_hash = {})
      @dictionary = IndifferentHash.new(yaml_hash)
      @dictionary.each do |key, info|
        if info === String
          @dictionary[key] = {source: info}
        end
      end
    end

    # pull out all the fields that are specified in
    # only: [one, two, three]
    # this means we should only take these fields from that file
    def only_field_list(only_names, all_fields)
      selected = {}
      only_names.each do |name|
        # select the exact match or all the fields with prefix "whatever."
        selected.merge!(all_fields.select { |k,v| name == k || name =~ /#{k}\..*/ })
      end
      selected
    end

    # return new fields Hash, with fields that will turn into the nested hash
    def make_nested(nest_config, all_fields)
      new_fields = {}
      selected = []
      nest_config['contents'].each do |key_name|
        # select the exact match or all the fields with prefix "whatever."
        selected += all_fields.keys.select { |name| name == key_name || name =~ /#{key_name}\..*/ }
      end
      nested_prefix = nest_config['key']
      selected.each do |name|
        new_fields["#{nested_prefix}.#{name}"] = all_fields[name]
      end
      new_fields
    end

    def file_config
      @data.fetch('files', [])
    end

    # returns a hash that lets us know the types of what we read from csv
    # key: the field names which map directly to csv columns
    # value: type
    def column_field_types
      if @column_types.nil?
        @column_types = {}
        dictionary.each do |field_name, info|
          type = info['type']
          @column_types[field_name] = type unless type.nil?
        end
      end
      @column_types
    end

    # this is a mapping of the fields that end up in the json doc
    # to their types, which might include nested documents
    # but at this stage, field names use dot syntax for nesting
    def field_types
      if @field_types.nil?
        @field_types = {}
        fields = {}
        file_config.each do |f|
          if f.keys == ['name']   # only filename, use all the columns
            fields.merge!(dictionary)
          else
            fields.merge!(only_field_list(f['only'], dictionary)) if f['only']
            fields.merge!(make_nested(f['nest'], dictionary)) if f['nest']
          end
        end
        fields.each do |field_name, info|
          type = info['type'] || "string"
          type = nil if field_name == 'location.lat' || field_name == 'location.lon'
          #logger.info "field #{field_name}: #{type.inspect}"
          @field_types[field_name] = type unless type.nil?
        end
      end
      @field_types
    end

    # update current configuration document in the index, if needed
    # return whether the current config was new and required an update
    def update_indexed_config
      updated = false
      old_config = nil
      index_name = scoped_index_name
      logger.info "looking for: #{index_name}"
      index_exists = false
      if DataMagic.client.indices.exists? index: index_name
        index_exists = true
        begin
          response = DataMagic.client.get index: index_name, type: 'config', id: 1
          old_config = response["_source"]
        rescue Elasticsearch::Transport::Transport::Errors::NotFound
          logger.debug "no prior index configuration"
        end
      end
      logger.debug "old config version (from es): #{(old_config.nil? ? old_config : old_config['version']).inspect}"
      logger.debug "new config version (from data.yaml): #{@data['version'].inspect}"
      if old_config.nil? || old_config["version"] != @data["version"]
        logger.debug "--------> new config -> new index: #{@data.inspect[0..255]}"
        DataMagic.client.indices.delete index: index_name if index_exists
        DataMagic.create_index(index_name, field_types)  ## DataMagic::Index.create ?
        DataMagic.client.index index: index_name, type:'config', id: 1, body: @data
        updated = true
      end
      updated
    end


    # reads a file or s3 object, returns a string
    # path follows URI pattern
    # could be
    #   s3://username:password@bucket_name/path
    #   s3://bucket_name/path
    #   s3://bucket_name
    #   a local path like: './data'
    def read_path(path)
      uri = URI(path)
      scheme = uri.scheme
      case scheme
        when nil
          File.read(uri.path)
        when "s3"
          key = uri.path
          key[0] = ''  # remove initial /
          response = @s3.get_object(bucket: uri.hostname, key: key)
          response.body.read
        else
          raise ArgumentError, "unexpected scheme: #{scheme}"
      end
    end

    def file_list(path)
      uri = URI(path)
      scheme = uri.scheme
      case scheme
        when nil
          Dir.glob("#{path}/*").map { |file| File.basename file }
        when "s3"
          logger.info "bucket: #{uri.hostname}"
          response = @s3.list_objects(bucket: uri.hostname)
          logger.info "response: #{response.inspect[0..255]}"
          response.contents.map { |item| item.key }
      end
    end

    def data_file_name(path)
      ['data.yml', 'data.yaml'].find { |file| file_list(path).include? file }
    end

    def load_yaml(path = nil)
      logger.info "load_yaml: #{path}"
      file = data_file_name(path)
      if file.nil? and not ENV['ALLOW_MISSING_YML']
        logger.warn "No data.y?ml found; using default options"
      end

      raw = file ? read_path(File.join(path, file)) : '{}'
      YAML.load(raw)
    end

    def list_files(path)
      Dir["#{path}/*"].select { |file|
        @extensions.include? File.extname(file)
      }.map { |file|
        File.basename file
      }
    end

    # if limit is not nil, truncate the length of list to limit
    def truncate_list(list, limit)
      logger.info("truncating list limit: #{limit.inspect}") unless limit.nil?
      limit.nil? ? list : list[0...limit]
    end

    # file_data from data.yaml is an array of hashes
    # must have a name, everything else is optional
    # fdata can be nil, then we get all files in path
    def parse_files(path, fdata = nil, options = {})
      logger.debug "parse_files: #{fdata.inspect}"
      logger.debug "options: #{options.inspect}"
      names = []
      if fdata.nil?
        names = list_files(path)
        fdata = []
      else
        fdata = truncate_list(fdata, options[:limit_files])
        fdata.each_with_index do |info, index|
          name = info.fetch('name', '')
          if name.empty?
            raise ArgumentError "file #{index}: 'name' must not be empty " +
                                "in #{fdata.inspect}"
          end
          names << name
        end
      end

      paths = names.map { |name| File.join(path, name) }

      return paths, fdata
    end

    def clean_index(path)
      uri = URI(path)
      File.basename(uri.hostname || uri.path).gsub(/[^0-9a-z]+/, '-')
    end

    def load_datayaml(directory_path = nil)
      logger.debug "---- Config.load -----"
      if directory_path.nil? or directory_path.empty?
        directory_path = data_path
      end

      if @data and @data['data_path'] == directory_path
        logger.debug "already loaded, nothing to do!"
      else
        logger.debug "load config #{directory_path.inspect}"
        @data = load_yaml(directory_path)
        @data['unique'] ||= []
        logger.debug "config: #{@data.inspect[0..600]}"
        @data['index'] ||= clean_index(@data_path)
        endpoint = @data['api'] || clean_index(@data_path)
        @dictionary = @data['dictionary'] || {}
        @data['options'] ||= {}
        Hashie.symbolize_keys! @data['options']
        @api_endpoints[endpoint] = {index: @data['index']}
        @files, @data['files'] = parse_files(directory_path, data['files'], data['options'])

        logger.debug "file_config: #{@data['files'].inspect}"
        logger.debug "no files found" if @data['files'].empty?

        # keep track of where we loaded our data, so we can avoid loading again
        @data['data_path'] = directory_path
        @data_path = directory_path  # make sure this is set, in case it changed
      end
      scoped_index_name
    end

  end # class Config
end # module DataMagic
