module DataMagic
  module Load
    class S3Adapter
      attr_reader :s3, :uri

      def initialize(uri, s3)
        @uri = uri
        @s3 = s3
      end

      def can_handle?
        uri.scheme == 's3'
      end

      def read
        response = s3.get_object(bucket: bucket, key: key)
        response.body.read
      rescue Aws::S3::Errors::NoSuchKey
        # we don't want to raise this one, might be expected
        nil
      rescue => e
        logger.debug "read_from_s3 failed: #{bucket} #{key} with #{e.class}:#{e.message}"
        raise e
      end

      def key
        key = uri.path
        key[0] = ''  # remove initial /
        key
      end

      def bucket
        uri.hostname
      end
    end
  end
end

