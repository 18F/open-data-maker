module DataMagic
  module Index
    class BuilderData
      attr_reader :data, :options

      def initialize(data, options)
        @options = options
        @data = data
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
end
