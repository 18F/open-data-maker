module DataMagic
  class BuilderData
    attr_reader :data, :options

    def initialize(data, options)
      @options = options
      @data = data
    end

    def normalize!
      @data = data.read if data.respond_to?(:read)
      @data.sub!("\xEF\xBB\xBF", "") # remove Byte Order Mark
      if options[:force_utf8]
        @data = data.encode('UTF-8', invalid: :replace, replace: '')
      end
      data.split('i-am-just-doing-this-to-detect-some-bad-utf8-sorry')
      data
    rescue ArgumentError => e
      raise DataMagic::InvalidData.new(e.message)
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
