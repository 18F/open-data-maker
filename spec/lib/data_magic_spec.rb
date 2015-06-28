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
    def address_data
      if @address_data.nil?
        data_str = <<-eos
name,address,city
Paul,15 Penny Lane,Liverpool
Michelle,600 Pennsylvania Avenue,Washington
Marilyn,1313 Mockingbird Lane,Burbank
Sherlock,221B Baker Street,London
Bart,742 Evergreen Terrace,Springfield
Paul,19 N Square,Boston
eos
        @address_data = StringIO.new(data_str)
      else
        @address_data.rewind
      end
      @address_data
    end

    describe "default" do
      before (:all) do
        num_rows, fields = DataMagic.import_csv('people', address_data)
      end

      after(:all) do
        DataMagic.delete_index('people')
      end

      it "can find an attribute from an imported file" do
        result = DataMagic.search({name: "Marilyn"}, index: 'people')
        expect(result).to eq([{"name" => "Marilyn", "address" => "1313 Mockingbird Lane", "city" => "Burbank"}])
      end
      
      it "can find based on multiple attributes from an imported file" do
        result = DataMagic.search({name: "Paul", city:"Liverpool"}, index: 'people')
        expect(result).to eq([{"name" => "Paul", "address" => "15 Penny Lane", "city" => "Liverpool"}])
      end

    end
    describe "with mapping" do
      before (:all) do
        options = {}
        options[:fields] = {name: 'person_name', address: 'street'}
        num_rows, fields = DataMagic.import_csv('people', address_data, options)
        expect(fields.sort).to eq(options[:fields].values.sort)
      end

      after(:all) do
        DataMagic.delete_index('people')
      end

      it "can find an attribute from an imported file" do
        result = DataMagic.search({person_name: "Marilyn" }, index: 'people')
        expect(result).to eq([{"person_name" => "Marilyn", "street" => "1313 Mockingbird Lane"}])
      end


    end


  end



  describe "#import_all" do

    before(:all) do
      dir_path = './spec/fixtures/import_all'
      @csv_files = Dir.glob("#{dir_path}/**/*.csv")
                            .select { |entry| File.file? entry }
      DataMagic.import_all(dir_path)
    end
    after(:all) do
      DataMagic.delete_index('city-data')
    end

    it "can get list of imported csv files" do
      expect(DataMagic.files.sort).to eq(@csv_files.sort)
    end

    it "can get index name from api endpoint" do
      expect(DataMagic.find_index_for('cities')).to eq('city-data')
    end

    it "indexes files with yaml mapping" do
      result = DataMagic.search({name: "Chicago"}, api: 'cities')
      expect(result).to eq([{"state"=>"IL", "name"=>"Chicago", "population"=>"2695598", "latitude"=>"41.837551", "longitude"=>"-87.681844"}])
    end

  end
end
