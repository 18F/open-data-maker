require 'spec_helper'
require 'data_magic'

describe DataMagic do
  describe "#import_csv" do
    it "throws error if datafile doesn't respond to read" do
      expect{DataMagic.import_csv('test-index', nil)}.to raise_error(ArgumentError)
    end

    it "throws errors for bad format" do
      data = StringIO.new("not a csv file")
      expect{DataMagic.import_csv('test-index', data)}.to raise_error(DataMagic::InvalidData)
    end

    it "stops importing when invalid UTF-8 chars are found" do
      expect{
        File.open('./spec/fixtures/invalid_utf8.csv') do |f|
          num_rows, fields = DataMagic.import_csv('test-index', f)
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
        reported_num_rows, fields = DataMagic.import_csv('test-index', f, force_utf8: true)
        expect(reported_num_rows).to eq(real_num_rows)
      end
    end


    it "reads file and reports number of rows and headers" do
      data_str = <<-eos
a,b
1,2
3,4
eos
      data = StringIO.new(data_str)
      num_rows, fields = DataMagic.import_csv('my-index', data)
      expect(num_rows).to be(2)
      expect(fields).to eq( [:a,:b] )

      DataMagic.delete_index('my-index')
    end
  end

  describe "#search" do
    before(:all) do
      data_str = <<-eos
name,address
Paul,15 Penny Lane
Michelle,600 Pennsylvania Avenue
Marilyn,1313 Mockingbird Lane
Sherlock,221B Baker Street
Bart,742 Evergreen Terrace
eos
      data = StringIO.new(data_str)
      num_rows, fields = DataMagic.import_csv('people', data)
    end

    after(:all) do
      DataMagic.delete_index('people')
    end

    it "can find an attribute from an imported file" do
      query = { query: { match: {name: "Paul" }}}
      result = DataMagic.search('people', query)
      expect(result).to eq([{"name" => "Paul", "address" => "15 Penny Lane"}])
    end

  end
end
