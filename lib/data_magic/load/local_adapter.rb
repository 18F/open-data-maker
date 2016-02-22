module DataMagic
  module Load
    class LocalAdapter
      attr_reader :uri

      def initialize(uri)
        @uri = uri
      end

      def can_handle?
        uri.scheme == nil
      end

      def read
        File.read(path)
      rescue => e
        if e.message.include? "No such file or directory"
          nil
        else
          logger.error "read_path_local failed: #{path} with #{e.class}:#{e.message}"
          raise e
        end
      end

      def path
        uri.path
      end
    end
  end
end
