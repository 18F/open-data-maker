module DataMagic
  module Config

    def self.logger
      @logger ||= Logger.new("log/#{ENV['RACK_ENV'] || 'development'}.log")
    end

    def self.files
      @files
    end

    def self.global_mapping
      @global_mapping
    end

    def self.data
      self.load if @data.empty?
      @data
    end

    def self.page_size
      @page_size
    end


    @data = {}
    @files = []
    @api_endpoints = {}
    @global_mapping = {}
    @page_size = 10

    def self.data_path
      path = ENV['DATA_PATH']
      if path.nil? or path.empty?
        path = DEFAULT_PATH
      end
      path
    end

    def self.additional_data_for_file(fname)
      @data['files'][fname]['add']
    end


    # path follows URI pattern
    # could be
    #   s3://username:password@bucket_name/path
    #   s3://bucket_name/path
    #   s3://bucket_name
    #   a local path like: './data'
    def self.read_path(path)
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

    def self.load(directory_path = nil)
      logger.debug "---- Config.load -----"
      if directory_path.nil? or directory_path.empty?
        directory_path = Config.data_path
      end
      logger.debug "load config #{directory_path.inspect}"
      @files = []
      config_data = Config.read_path("#{directory_path}/data.yaml")
      @data = YAML.load(config_data)
      logger.debug "config: #{@data.inspect}"
      index = @data['index'] || 'general'
      endpoint = @data['api'] || 'data'
      @global_mapping = @data['global_mapping'] || {}
      @api_endpoints[endpoint] = {index: index}

      file_config = @data['files']
      logger.debug "file_config: #{file_config.inspect}"
      if file_config.nil?
        logger.debug "no files found"
      else
        fnames = @data["files"].keys

        fnames.each do |fname|
          @data["files"][fname] ||= {}
          @files << File.join(directory_path, fname)
        end
      end
      index
    end

    # returns an array of api_endpoints
    # list of strings
    def self.api_endpoint_names
      Config.load_if_needed
      @api_endpoints.keys
    end


    def self.find_index_for(api)
      Config.load_if_needed
      api_info = @api_endpoints[api] || {}
      api_info[:index]
    end

    # update current configuration document in the index, if needed
    # return whether the current config was new and required an update
    def self.new?(external_index_name)
      updated = false
      old_config = nil
      index_name = DataMagic.scoped_index_name(external_index_name)
      logger.info "looking for: #{index_name}"
      if DataMagic.client.indices.exists? index: index_name
        begin
          response = DataMagic.client.get index: index_name, type: 'config', id: 1
          old_config = response["_source"]
        rescue Elasticsearch::Transport::Transport::Errors::NotFound
          logger.debug "no prior index configuration"
        end
      else
        logger.debug "creating index"
        DataMagic.create_index(index_name)
      end
      logger.debug "old_config: #{old_config.inspect}"
      logger.debug "old_config: #{@data.inspect}"
      if old_config.nil? || old_config["version"] != @data["version"]
        logger.debug "--------> adding config to index: #{@data.inspect}"
        DataMagic.client.index index: index_name, type:'config', id: 1, body: @data
        updated = true
      end
      updated
    end

    def self.needs_loading?
      @files.empty?
    end

    def self.load_if_needed
      Config.load if needs_loading?
    end

    def self.init(s3 = nil)
      @files = []
      @config = {}
      @api_endpoints = {}
      @s3 = s3
      @data = {}
    end

  end
end
