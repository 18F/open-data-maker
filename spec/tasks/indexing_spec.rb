require 'spec_helper'
require 'bundler/setup'
require 'padrino-core/cli/rake'

describe 'elastic search index management rake tasks' do
  before do
    PadrinoTasks.init
    DataMagic::Config.init
  end
  
  context "imports" do
    it "default sample-data" do
      ENV['DATA_PATH'] = nil
      expect { Rake::Task['import'].invoke }.not_to raise_exception
      DataMagic.delete_index('city-data')
    end

    it "correct configuration" do
      dir_path = './spec/fixtures/import_all'
      ENV['DATA_PATH'] = dir_path
      expect { Rake::Task['import'].invoke }.not_to raise_exception
      expect(DataMagic::Config.api_endpoint_names).to eq(['cities'])
      DataMagic.delete_index('city-data')
    end

  end

end
