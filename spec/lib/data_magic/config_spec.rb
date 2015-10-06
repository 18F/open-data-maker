require 'spec_helper'

describe DataMagic::Config do
  before(:all) do
    ENV['DATA_PATH'] = './spec/fixtures/import_with_dictionary'
  end

  it "detects data.yml files" do
    ENV['DATA_PATH'] = './spec/fixtures/cities_with_yml'
    config = DataMagic::Config.new
    expect(config.data["api"]).to eq("cities")
  end

  describe 'slugification' do
    it 'slugifies local paths' do
      config = DataMagic::Config.new
      slugified = config.clean_index('path/to/my_directory')
      expect(slugified).to eq('my-directory')
    end

    it 'slugifes s3 bucket names' do
      config = DataMagic::Config.new
      slugified = config.clean_index('s3://user:pass@my_bucket')
      expect(slugified).to eq('my-bucket')
    end
  end

  context "s3" do
    it "detects data.yaml" do
      ENV['DATA_PATH'] = 's3://mybucket'
      fake_s3 = class_spy("Fake Aws::S3::Client")
      fake_get_object_response = double(
        "S3 response",
        body: StringIO.new({ 'index' => 'fake-index' }.to_yaml)
      )
      fake_list_objects_response = double(
        "S3 response",
        contents: [double("item", key: "data.yaml")]
      )

      allow(fake_s3).to receive(:get_object)
        .with(bucket: 'mybucket', key: 'data.yaml')
        .and_return(fake_get_object_response)
      allow(fake_s3).to receive(:list_objects)
        .with(bucket: 'mybucket')
        .and_return(fake_list_objects_response)
      config = DataMagic::Config.new(s3: fake_s3)
      expect(config.s3).to eq(fake_s3)
      expect(config.data["index"]).to eq("fake-index")
    end
  end

  context "create" do
    it "works with zero args" do
      expect(DataMagic::Config.new).to_not be_nil
    end
    it "can set s3 client" do
      # TODO: mock s3
      s3_client = "s3 client"
      config = DataMagic::Config.new(s3: s3_client)
      expect(config.s3).to eq(s3_client)
    end
  end

  context "when loaded" do
    let(:config) { DataMagic::Config.new }

    after do
      config.clear_all
    end

    context "#scoped_index_name" do
      it "includes environment prefix" do
        expect(config.scoped_index_name).to eq('test-city-data')
      end
    end

    it "has config data" do
      default_config = {
        "version" => "cities100-2010",
        "index" => "city-data", "api" => "cities",
        "files" => [{ "name" => "cities100.csv" }],
        "data_path" => "./sample-data",
        "options" => {:search=>"dictionary_only"},
        "unique" => ["name"],
        "data_path" => "./sample-data"
      }
      expect(config.data.keys).to include('dictionary')
      dictionary = config.data.delete 'dictionary'

      expect(dictionary.keys.sort).to eq %w(id code name state population
        location.lat location.lon area.land area.water).sort
      categories = config.data.delete 'categories'
      expect(categories.keys.sort).to eq %w(general general2 general3 general4 general5 geographic).sort
      expect(config.data).to eq(default_config)
    end

    it "has default page size" do
      expect(DataMagic::DEFAULT_PAGE_SIZE).to_not be_nil
      expect(config.page_size).to eq(DataMagic::DEFAULT_PAGE_SIZE)
    end

    describe "#update_indexed_config" do # rename ... or do this in load_config or something
      context "after loading config" do
        let(:fixture_path) { "./spec/fixtures/import_with_dictionary" }
        before do
          config.load_datayaml(fixture_path)
        end
        it "should be true" do
          expect(config.update_indexed_config).to be true
        end
        it "should set new data_path" do
          expect(config.data_path).to eq(fixture_path)
        end

        it "twice should be false" do
          config.update_indexed_config
          expect(config.update_indexed_config).to be false
        end
      end
    end

    describe "when has a custom null_value" do
      it 'should have a default null value' do
        expect(config.null_value).to eq('NULL')
      end

      it 'should set null value field' do
        config.load_datayaml("./spec/fixtures/import_with_null_value")
        expect(config.null_value).to eq('abc123')
      end
    end
  end

  context ".calculated_field_list" do
    let(:config) { DataMagic::Config.new(load_datayaml: false) }
    it "finds fields with 'calculate' property" do
      allow(config).to receive(:dictionary).and_return(
        {
          one: {
            source: 'column1',
            type: 'float'
          },
          two: {
            source: 'column2',
            type: 'float'
          },
          all: {
                calculate: 'column1 or column2',
                type: 'float',
                description: 'something'
            }
        }
      )
      expect(config.calculated_field_list).to eq(['all'])
    end
  end

  context ".only_field_list" do
    let(:config) { DataMagic::Config.new(load_datayaml: false) }
    let(:simple_fields) do
      { 'one' => 'column1', 'two' => 'column2', 'three' => 'column3' }
    end
    let(:fields_with_dots) do
      { 'one' => 'column1', 'two.a' => 'column2a', 'two.b' => 'column2b' }
    end

    it "selects a subset" do
      expect(config.only_field_list(%w(one two), simple_fields)).to eq(
        'one' => 'column1', 'two' => 'column2'
      )
    end

    it "selects fields with dots" do
      expect(config.only_field_list(%w(two), fields_with_dots)).to eq(
        'two.a' => 'column2a', 'two.b' => 'column2b'
      )
    end
  end
end
