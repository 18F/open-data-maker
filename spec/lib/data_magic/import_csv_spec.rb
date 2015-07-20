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

  describe "error while reading" do
    it "throws errors for bad format" do
      data = StringIO.new("not csv format")
      expect{DataMagic.import_csv(data)}.to raise_error(DataMagic::InvalidData)
    end

    it "stops importing when invalid UTF-8 chars are found" do
      expect{
        File.open('./spec/fixtures/invalid_utf8.csv') do |f|
          num_rows, fields = DataMagic.import_csv(f)
          expect(num_rows).to eq(0)
          # note: with some files it imports some data
          # in that case an exception won't be raised, but haven't been able
          # to repro as a test case
        end
      }.to raise_error(DataMagic::InvalidData)
    end

    it "allows importing invalid utf8 with force_utf8 option" do
      real_num_rows = File.read('./spec/fixtures/invalid_utf8.csv').lines.count - 1
      File.open('./spec/fixtures/invalid_utf8.csv') do |f|
        reported_num_rows, fields = DataMagic.import_csv(f, force_utf8: true)
        expect(reported_num_rows).to eq(real_num_rows)
      end
    end
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
    expect(fields).to eq( [:a,:b] )
  end

end
