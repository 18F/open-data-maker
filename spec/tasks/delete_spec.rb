require 'spec_helper'
require 'bundler/setup'
require 'padrino-core/cli/rake'

describe 'elastic search delete task' do
  before do
    PadrinoTasks.init
    ENV['DATA_PATH'] = nil
    DataMagic::Config.init
    DataMagic.import_all
  end
  let(:index_name) {'city-data'}

  context "deletes" do
    it "one index" do
      ENV['DATA_PATH'] = nil
      expect(DataMagic.client.indices.exists?(index: 'test-city-data')).to be true
      expect { Rake::Task["delete"].invoke(index_name) }.not_to raise_exception
      expect(DataMagic.client.indices.exists?(index: 'test-city-data')).to be false
    end


  end

end
