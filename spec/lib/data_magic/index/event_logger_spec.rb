require 'spec_helper'
require 'data_magic'

describe DataMagic::Index::EventLogger do
  let(:event_logger) {
    l = DataMagic::Index::EventLogger.new
    allow(l).to receive(:logger).and_return(logger)
    l
  }

  let(:logger) { double('logger') }

  context 'when triggering an event with only a message argument' do
    it 'logs the message with the right level' do
      expect(logger).to receive(:info).with('hey!')
      event_logger.trigger('info', 'hey!')

      expect(logger).to receive(:debug).with('what happened?')
      event_logger.trigger('debug', 'what happened?')

      expect(logger).to receive(:warn).with('dude? everything ok?')
      event_logger.trigger('warn', 'dude? everything ok?')

      expect(logger).to receive(:error).with('FIRE IN THE HOLE!')
      event_logger.trigger('error', 'FIRE IN THE HOLE!')
    end
  end

  context 'when triggering an event with a message and an object' do
    it 'logs as a key value pair with an inspection of the object' do
      expect(logger).to receive(:info).with("foo: {:wild=>\"bar\"}")
      event_logger.trigger('info', 'foo', {wild: 'bar'})
    end

    it 'will shorten the object inspection when provided a limit' do
      expect(logger).to receive(:warn).with("foo: {:wild")
      event_logger.trigger('warn', 'foo', {wild: 'bar'}, 5)
    end
  end
end
