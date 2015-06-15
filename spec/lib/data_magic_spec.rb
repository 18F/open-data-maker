require 'spec_helper'
require 'data_magic'

describe DataMagic do

  describe "#import_csv" do
    it "throws errors for bad format" do
      data = StringIO.new("not a csv file")
      expect{DataMagic.import_csv('test-index', data)}.to raise_error
    end

    it "reads file and reports number of rows and headers" do
      data_str = <<-eos
a,b
1,2
3,4
eos
      data = StringIO.new(data_str)
      num_rows, fields = DataMagic.import_csv('test-index', data)
      expect(num_rows).to be(2)
      expect(fields).to eq( [:a,:b] )
    end
  end

  describe "#search" do
    before do
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

    it "can find an attribute from an imported file" do
      query = { term: { name: "Paul" }}
      result = DataMagic.search('people', query)
      expect(result).to eq({name:'Paul', address:'15 Penny Lane'})
    end

  end
end
