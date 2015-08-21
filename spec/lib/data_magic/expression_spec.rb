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
    result = DataMagic.search({id: 1}, fields: ['id', 'completion.rate.overall'] )
    expect(result['results'].first).to eq({'id' => 1, 'completion.rate.overall' => 0.16 })
  end

end
