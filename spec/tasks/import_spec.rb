require 'spec_helper'
require 'bundler/setup'
require 'padrino-core/cli/rake'

describe 'elastic search index management rake task' do
  before do
    PadrinoTasks.init
    DataMagic.init(load_now: true)
  end

  after do
    DataMagic.destroy
  end

  context "imports" do
    it "default sample-data" do
      ENV['DATA_PATH'] = nil
      expect { Rake::Task['import'].invoke }.not_to raise_exception
    end

    it "correct configuration" do
      dir_path = './spec/fixtures/import_with_dictionary'
      ENV['DATA_PATH'] = dir_path
      expect { Rake::Task['import'].invoke }.not_to raise_exception
      expect(DataMagic.config.api_endpoint_names).to eq(['cities'])
    end

  end

end
