require 'spec_helper'
require 'data_magic'

describe "DataMagic #init" do
  before (:all) do
    ENV['DATA_PATH'] = './spec/fixtures/import_with_dictionary'
  end

  after(:each) do
    DataMagic.destroy
  end

  context "with no options" do
    it "creates index only once" do
      expect(DataMagic).to receive(:create_index).once
      DataMagic.init
    end

    it "creates index" do
      DataMagic.init
      expect(DataMagic.config.index_exists?).to be true
    end

    it "does not re-create index with subsequent call to #import_with_dictionary" do
      expect(DataMagic).to receive(:create_index).once
      DataMagic.init
      DataMagic.import_with_dictionary
    end
  end


  context "with load_now: false" do
    it "does not call #create_index" do
      expect(DataMagic).not_to receive(:create_index)
      DataMagic.init(load_now: false)
    end

    it "does not create index" do
      DataMagic.init(load_now: false)
      expect(DataMagic.config.index_exists?).to be false
    end

    it "creates index with subsequent call to #import_with_dictionary" do
      DataMagic.init(load_now: false)
      DataMagic.import_with_dictionary
      expect(DataMagic.config.index_exists?).to be true
    end

    it "creates index with subsequent call to #import_csv" do
      ENV['DATA_PATH'] = './spec/fixtures/minimal'
      DataMagic.init(load_now: false)
      data_str = <<-eos
      a,b
      1,2
      3,4
      eos
      data = StringIO.new(data_str)
      DataMagic.import_csv(data)
      expect(DataMagic.config.index_exists?).to be true
    end
  end
end