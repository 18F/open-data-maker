require 'spec_helper'

describe 'elastic search index management tasks' do

  context "imports" do
    before do
      DataMagic.delete_index('cities')
      DataMagic.delete_index('places')
    end

    it "default sample-data" do
      expect { DataMagic.import_all }.not_to raise_exception
    end

    it "correct configuration" do
      dir_path = './spec/fixtures/import_all'
      ENV['DATA_PATH'] = dir_path
      expect { DataMagic.import_all }.not_to raise_exception
      expect(DataMagic::Config.api_endpoint_names).to eq(['cities'])
    end

  end

end
