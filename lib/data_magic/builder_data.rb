module DataMagic

  class BuilderData
    attr_reader :data, :options
    def initialize(data, options)
      @options = options
      @data = data
    end

    def normalize!
      @data = @data.read if @data.respond_to?(:read)
      @data.sub!("\xEF\xBB\xBF", "") # remove Byte Order Mark
      if options[:force_utf8]
        @data = @data.encode('UTF-8', invalid: :replace, replace: '')
      end
      @data
    end

    def log_metadata
      logger.debug "additional_data: #{additional_data.inspect}"
      logger.debug "  new_field_names: #{new_field_names.inspect[0..500]}"
      logger.debug "  options: #{options.reject { |k,v| k == :mapping }.to_yaml}"
    end

    def additional_fields
      options[:mapping] || {}
    end

    def new_field_names
      field_names = options[:fields] || {}
      field_names.merge(additional_fields)
    end

    def additional_data
      options[:add_data]
    end
  end


end
