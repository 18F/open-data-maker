require 'spec_helper'
require 'data_magic'

describe "unique key(s)" do

  before :example do
    DataMagic.destroy
    ENV['DATA_PATH'] = './spec/fixtures/schools'
  end
  after :example do
    DataMagic.destroy
  end

  it "can combine two columns" do
    DataMagic.config = DataMagic::Config.new
    DataMagic.import_with_dictionary
    result = DataMagic.search({})
    expect(result['results']).to eq({})
  end

end
