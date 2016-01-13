require 'spec_helper'
require 'data_magic'

describe "DataMagic #import_without_data_yaml" do
  describe "without ALLOW_MISSING_YML" do
    it "not found locally raises error" do
      ENV['DATA_PATH'] = './spec/fixtures/cities_without_yml'
      expect {
        DataMagic.init(load_now: true)
      }.to raise_error(IOError, "No data.y?ml found at ./spec/fixtures/cities_without_yml. Did you mean to define ALLOW_MISSING_YML environment variable?")
    end
    it "not found on s3 raises error" do
      ENV['DATA_PATH'] = 's3://mybucket'
      fake_s3 = Aws::S3::Client.new(stub_responses: true)
      fake_s3.stub_responses(:get_object, Aws::S3::Errors::NoSuchKey.new(Seahorse::Client::RequestContext, 'Fake Error'))
      expect {
        config = DataMagic::Config.new(s3: fake_s3)
      }.to raise_error(IOError, "No data.y?ml found at s3://mybucket. Did you mean to define ALLOW_MISSING_YML environment variable?")
    end

  end
  describe "with ALLOW_MISSING_YML" do
    let (:expected) do
      {
        "metadata" => {
          "total" => 1,
          "page" => 0,
          "per_page" => DataMagic::DEFAULT_PAGE_SIZE
        },
        "results" => 	[]
      }
    end

    before(:all) do
      DataMagic.destroy
      ENV['ALLOW_MISSING_YML'] = 'allow'
      ENV['DATA_PATH'] = './spec/fixtures/cities_without_yml'
      DataMagic.init(load_now: true)
    end
    after(:all) do
      DataMagic.destroy
      ENV['ALLOW_MISSING_YML'] = ''
    end

    it "can get list of imported csv files" do
      file_list = [
        "./spec/fixtures/cities_without_yml/cities50.csv",
        "./spec/fixtures/cities_without_yml/cities51-100.csv",
        "./spec/fixtures/cities_without_yml/more.csv",
      ]
      expect(DataMagic.config.files.sort).to eq(file_list)
    end

    it "can get index name from api endpoint" do
      expect(DataMagic.config.find_index_for('cities-without-yml')).to eq('cities-without-yml')
    end

    it "indexes files with yaml mapping" do
      result = DataMagic.search({NAME: "Chicago"}, api: 'cities-without-yml')
      expected["results"] = [
        {
          "USPS"=>"IL",
          "GEOID"=>"1714000",
          "ANSICODE"=>"00428803",
          "NAME"=>"Chicago",
          "LSAD"=>"25",
          "FUNCSTAT"=>"A",
          "POP10"=>"2695598",
          "HU10"=>"1194337",
          "ALAND"=>"589571105",
          "AWATER"=>"16781658",
          "ALAND_SQMI"=>"227.635",
          "AWATER_SQMI"=>"6.479",
          "INTPTLAT"=>"41.837551",
          "INTPTLONG"=>"-87.681844",
        }
      ]
      expect(result).to eq(expected)
    end
  end
end
