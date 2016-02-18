require 'spec_helper'
require 'data_magic'

describe "DataMagic::Index::BuilderData #normalize!" do
  it 'converts file handles to their contents' do
    f = File.new('./spec/fixtures/cities_without_yml/cities50.csv')
    builder_data = DataMagic::Index::BuilderData.new(f, {})
    builder_data.normalize!
    expect(builder_data.data).to be_a(String)
  end

  it "stops importing when invalid UTF-8 chars are found" do
    builder_data = DataMagic::Index::BuilderData.new("hi \xAD", {})
    expect{
      builder_data.normalize!
    }.to raise_error(DataMagic::InvalidData)
  end

  it "allows importing of invalid UTF-8 when options force utf8" do
    builder_data = DataMagic::Index::BuilderData.new("hi \xAD", {force_utf8: true})
    builder_data.normalize!
    expect(builder_data.data).to eq("hi ")
  end

  it "strips the byte order mark, if present" do
    f = File.new('./spec/fixtures/bom/bom.csv')
    builder_data = DataMagic::Index::BuilderData.new(f, {})
    builder_data.normalize!
    expect(builder_data.data).to_not include("\xEF\xBB\xBF")
  end
end
