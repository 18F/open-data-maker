require 'spec_helper'
require 'data_magic'

describe "DataMagic name types" do

  before :example do
    DataMagic.destroy
    ENV['DATA_PATH'] = './spec/fixtures/types'
    DataMagic.init(load_now: true)
  end
  after :example do
    DataMagic.destroy
  end

  it "can search for one word" do
    response = DataMagic.search({'city.name' => 'New'}, fields:['city.name'])
    results = response['results'].sort {|a,b| a['city.name'] <=> b['city.name']}
    expect(results).to eq(
      [{"city.name"=>"New Orleans"}, {"city.name"=>"New York"}])
  end

  it "can search for multiple words" do
    response = DataMagic.search({'city.name' => 'New York'}, fields:['city.name'])
    results = response['results']
    expect(results).to eq(
      [{"city.name"=>"New York"}])
  end

  it "can search for partial words" do
    response = DataMagic.search({'city.name' => 'S Fran'}, fields:['city.name'])
    results = response['results']
    expect(results).to eq(
      [{"city.name"=>"San Francisco"}])
  end

  it "is not case sensitive" do
    response = DataMagic.search({'city.name' => 'nEW'}, fields:['city.name'])
    results = response['results'].sort {|a,b| a['city.name'] <=> b['city.name']}
    expect(results).to eq(
      [{"city.name"=>"New Orleans"}, {"city.name"=>"New York"}])
  end
end
