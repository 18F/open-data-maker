module DataMagic
  module Index
    class EventLogger
      attr_reader :importer

      def initialize(importer)
        @importer = importer
      end

      def trigger(event, *args)
        self.send(event, *args)
      end

      def debug(message, object=nil, limit=nil)
        logger.debug(full_message(message, object, limit))
      end

      def info(message, object=nil, limit=nil)
        logger.info(full_message(message, object, limit))
      end

      def warn(message, object=nil, limit=nil)
        logger.warn(full_message(message, object, limit))
      end

      def full_message(prefix, object, limit)
        return prefix unless object
        message = "#{prefix}: "
        if limit
          message << object.inspect[0..limit]
        else
          message << object.inspect
        end
        message
      end
    end
  end
end
