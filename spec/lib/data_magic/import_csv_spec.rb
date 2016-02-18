require 'spec_helper'
require 'data_magic'

describe "DataMagic #import_csv" do
  before do
    ENV['DATA_PATH'] = './spec/fixtures/minimal'
    DataMagic.init(load_now: false)
  end
  after do
    DataMagic.destroy
    #expect(DataMagic.client.indices.get(index: '_all')).to be_empty
  end

  it "throws errors for bad format" do
    data = StringIO.new("not csv format")
    expect{DataMagic.import_csv(data)}.to raise_error(DataMagic::InvalidData)
  end

  it "reads file and reports number of rows and headers" do
    data_str = <<-eos
a,b
1,2
3,4
eos
    data = StringIO.new(data_str)
    num_rows, fields = DataMagic.import_csv(data)
    expect(num_rows).to be(2)
    expect(fields).to eq(['a', 'b'])
  end

end
