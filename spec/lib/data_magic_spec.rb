require 'spec_helper'
require 'data_magic'

describe DataMagic do

  describe "#import_csv" do
    it "throws errors for bad format" do
      data = StringIO.new("not a csv file")
      expect{DataMagic.import_csv(data)}.to raise_error
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
end
