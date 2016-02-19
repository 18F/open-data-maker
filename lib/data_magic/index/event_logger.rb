module DataMagic
  module Index
    class EventLogger
      def trigger(event, *args)
        self.send(event, *args)
      end

      ['debug', 'info', 'warn', 'error'].each do |level|
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{level}(message, object=nil, limit=nil)
            logger.#{level}(full_message(message, object, limit))
          end
        RUBY
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
