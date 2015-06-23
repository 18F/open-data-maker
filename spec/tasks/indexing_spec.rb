require 'spec_helper'
require 'bundler/setup'
require 'padrino-core/cli/rake'

describe 'elastic search index management tasks' do
  before do
    PadrinoTasks.init
  end

  it { expect { Rake::Task['delete:all'].invoke }.not_to raise_exception }

  context "imports" do
    it "default sample-data" do
      expect { Rake::Task['import'].invoke }.not_to raise_exception
      DataMagic.delete_all
    end

    it "correct configuration" do
      dir_path = './spec/fixtures/import_all'
      ENV['DATA_PATH'] = dir_path
      expect { Rake::Task['import'].invoke }.not_to raise_exception
      expect(DataMagic.api_endpoint_names).to eq(['cities'])
    end

  end

end
