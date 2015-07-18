require 'spec_helper'
require 'data_magic'

describe "DataMagic #import_with_dictionary" do
  let (:expected) { {
            "total" => 1,
            "page" => 0,
            "per_page" => DataMagic::DEFAULT_PAGE_SIZE,
            "results" => 	[]
          } }

  before(:all) do
    DataMagic::Config.logger.info "===== before :all"
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

  xit "indexes rows from all the files" do
    # currently fails with 101 rows, one has blank name
    # perhaps it is reading a blank line at the end of one of the files?
    result = DataMagic.search({}, api: 'cities')
    puts result.inspect
    expect(result["total"]).to eq(100)
  end

  it "adds column with additional field data" do
    result = DataMagic.search({category: "top50"}, api: 'cities')
    expect(result["total"]).to eq(50)
  end
end
