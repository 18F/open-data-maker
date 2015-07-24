require 'spec_helper'
require 'data_magic'

describe "DataMagic #import_without_data_yaml" do
  let (:expected) { {
            "total" => 1,
            "page" => 0,
            "per_page" => DataMagic::DEFAULT_PAGE_SIZE,
            "results" => 	[]
          } }

  before(:all) do
    DataMagic::Config.logger.info "===== before :all"
    DataMagic.destroy
    ENV['DATA_PATH'] = './spec/fixtures/cities_without_yml'
    DataMagic.init(load_now: true)
  end
  after(:all) do
    DataMagic.destroy
  end

  it "can get list of imported csv files" do
    file_list = [
      "./spec/fixtures/cities_without_yml/cities50.csv",
      "./spec/fixtures/cities_without_yml/cities51-100.csv",
      "./spec/fixtures/cities_without_yml/more.csv",
    ]
    expect(DataMagic.config.files).to eq(file_list)
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
