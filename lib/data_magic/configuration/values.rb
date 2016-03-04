module DataMagic
  module Configuration
    class Values
      attr_writer :api_endpoints, :files, :dictionary, :page_size, :extensions, :data

      def api_endpoints
        @api_endpoints ||= {}
      end

      def dictionary
        @dictionary ||= {}
      end

      def data
        @data ||= {}
      end

      def files
        @files ||= []
      end

      def page_size
        @page_size ||= DataMagic::DEFAULT_PAGE_SIZE
      end

      def extensions
        @extensions ||= DataMagic::DEFAULT_EXTENSIONS
      end
    end
  end
end

