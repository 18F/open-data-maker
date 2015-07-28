require 'spec_helper'
require 'data_magic'

describe "DataMagic #import_with_dictionary" do
  let (:expected) { {
            "total" => 1,
            "page" => 0,
            "per_page" => DataMagic::DEFAULT_PAGE_SIZE,
            "results" => 	[]
          } }

  context "with common options" do
    before(:all) do
      DataMagic.destroy
      ENV['DATA_PATH'] = './spec/fixtures/import_with_dictionary'
      DataMagic.init(load_now: true)
    end
    after(:all) do
      DataMagic.destroy
    end

    it "can get list of imported csv files" do
      file_list = ["./spec/fixtures/import_with_dictionary/cities50.csv",
                   "./spec/fixtures/import_with_dictionary/cities51-100.csv"]
      expect(DataMagic.config.files).to eq(file_list)
    end

    it "can get index name from api endpoint" do
      expect(DataMagic.config.find_index_for('cities')).to eq('city-data')
    end

    it "indexes files with yaml mapping" do
      result = DataMagic.search({name: "Chicago"}, api: 'cities')
      expected["results"] = [
        { "state"=>"IL", "name"=>"Chicago",
          "population"=>"2695598",
          "latitude"=>"41.837551", "longitude"=>"-87.681844",
          "category"=>"top50"
        }
      ]
      expect(result).to eq(expected)
    end

    it "indexes rows from all the files" do
      result = DataMagic.search({}, api: 'cities')
      expect(result["total"]).to eq(100)
    end

    it "adds column with additional field data" do
      result = DataMagic.search({category: "top50"}, api: 'cities')
      expect(result["total"]).to eq(50)
    end
  end
  context "with option import: all" do
    before(:all) do
      DataMagic.destroy
      ENV['DATA_PATH'] = './spec/fixtures/import_with_options'
      DataMagic.init(load_now: true)
    end
    after(:all) do
      DataMagic.destroy
    end
    it "can index all columns and apply dictionary mapping to some" do
      result = DataMagic.search({GEOID: "3651000"}, api: 'cities')
      expected["results"] = [{"state"=>"NY", "GEOID"=>"3651000",
                              "ANSICODE"=>"2395220", "name"=>"New York",
                              "population"=>"8175133", "year"=>2010}]
      expect(result).to eq(expected)
    end
  end
  context "with option import: all" do
    before(:all) do
      DataMagic.destroy
      ENV['DATA_PATH'] = './spec/fixtures/import_with_options'
      DataMagic.init(load_now: true)
    end
    after(:all) do
      DataMagic.destroy
    end
    it "can index all columns and apply dictionary mapping to some" do
      result = DataMagic.search({GEOID: "3651000"}, api: 'cities')
      expected["results"] = [{"state"=>"NY", "GEOID"=>"3651000",
                              "ANSICODE"=>"2395220", "name"=>"New York",
                              "population"=>"8175133", "year"=>2010}]
      expect(result).to eq(expected)
    end
  end
  context "with option import: all" do
    before(:all) do
      DataMagic.destroy
      ENV['DATA_PATH'] = './spec/fixtures/import_with_options'
      DataMagic.init(load_now: true)
    end
    after(:all) do
      DataMagic.destroy
    end
    it "can index all columns and apply dictionary mapping to some" do
      result = DataMagic.search({GEOID: "3651000"}, api: 'cities')
      expected["results"] = [{"state"=>"NY", "GEOID"=>"3651000",
                              "ANSICODE"=>"2395220", "name"=>"New York",
                              "population"=>"8175133", "year"=>2010}]
      expect(result).to eq(expected)
    end
  end
  context "with BOM (byte order mark)" do
    before(:all) do
      DataMagic.destroy
      ENV['DATA_PATH'] = './spec/fixtures/bom'
      DataMagic.init(load_now: true)
    end
    after(:all) do
      DataMagic.destroy
    end
    it "can index all columns and apply dictionary mapping to some" do
      result = DataMagic.search({UNITID: "100654"}, api: 'test')
      expected["results"] = [{"id"=>"100654", "value"=>"00100200"}]
      expect(result).to eq(expected)
    end
  end
end
