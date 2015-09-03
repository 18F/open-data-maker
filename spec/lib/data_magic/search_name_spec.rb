require 'spec_helper'
require 'data_magic'

describe "DataMagic intuitive search" do

  before :example do
    DataMagic.destroy
    ENV['DATA_PATH'] = './spec/fixtures/school_names'
    DataMagic.init(load_now: true)
  end
  after :example do
    DataMagic.destroy
  end

  it "can search for exact match" do
    response = DataMagic.search({'school.name' => 'New York University'}, fields:['school.name'])
    results = response['results']
    expect(response).to eq(
      [{"school.name"=>"New York University"}])
  end
end
