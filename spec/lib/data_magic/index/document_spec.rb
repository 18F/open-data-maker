require 'spec_helper'
require 'data_magic'

describe DataMagic::Index::Document do
  before do
    allow(DataMagic).to receive(:config).and_return(config)
  end

  let(:document) { DataMagic::Index::Document.new(data) }
  let(:config) { DataMagic::Config.new() }
  let(:data) { {} }

  context 'when configured without any unique keys' do
    before do
      config.data['unique'] = []
    end

    it 'id should be nil' do
      expect(document.id).to be(nil)
    end

    it 'id should not be empty though' do
      expect(document.id_empty?).to be_falsey
    end
  end

  context 'when configured with the default keys' do
    context 'and there is no data' do
      it 'id should be an empty string' do
        expect(document.id).to eq('')
      end

      it 'id should be considered empty' do
        expect(document.id_empty?).to be_truthy
      end
    end

    context 'when there is data' do
      let(:data) {
        {"name" => "foo", "state"=>"MA"}
      }

      it 'id should be the value for the name key' do
        expect(document.id).to eq('foo')
      end

      it 'id should not be considered empty' do
        expect(document.id_empty?).to be_falsey
      end
    end
  end

  context 'with custom id configuration' do
    let(:data) {
      {"name" => "foo", "state"=>"MA"}
    }

    before do
      config.data['unique'] = ['name', 'state']
    end

    it 'id should build the right id for the data' do
      expect(document.id).to eq('foo:MA')
    end

    it 'id should not be considered empty' do
      expect(document.id_empty?).to be_falsey
    end
  end
end
