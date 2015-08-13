require 'spec_helper'
require 'data_magic'

describe "unique key(s)" do

  before :example do
    DataMagic.destroy
    ENV['DATA_PATH'] = './spec/fixtures/nested_files'
  end
  after :example do
    DataMagic.destroy
  end

  it "creates one document per unique id" do
    DataMagic.config = DataMagic::Config.new
    DataMagic.import_with_dictionary
    result = DataMagic.search({})
    expect(result['total']).to eq(10)
  end

  context "can import a subset of fields" do
    it "and doesn't find column" do
      DataMagic.config = DataMagic::Config.new
      DataMagic.import_with_dictionary
      result = DataMagic.search({zip: "35762"})
      expect(result['total']).to eq(0)
    end
    it "and doesn't include extra field" do
      DataMagic.config = DataMagic::Config.new
      DataMagic.import_with_dictionary
      response = DataMagic.search({})
      expect(response['results'][0]['zip']).to be(nil)
    end
  end

  it "can search on a nested field" do
    DataMagic.config = DataMagic::Config.new
    DataMagic.import_with_dictionary
    result = DataMagic.search({'2013.earnings.median' => 26318})
    expect(result['total']).to eq(1)
    first = result['results'].first
    expect(first['2013']['earnings']).to eq({"percent_gt_25k"=>0.53, "median"=>26318})
  end

end
