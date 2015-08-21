require 'spec_helper'

describe 'DataMagic::Config #field_types' do
  let(:config) { DataMagic::Config.new(load_datayaml: false) }

  it "returns empty if dictionary is empty" do
    allow(config).to receive(:file_config).and_return([{'name' => 'one.csv'}])
    allow(config).to receive(:dictionary).and_return({})
    expect(config.field_types).to eq({})
  end

  context "when no type is given" do
    before do
      allow(config).to receive(:file_config).and_return([{'name' => 'one.csv'}])
      allow(config).to receive(:dictionary).and_return({
          'name' => {source:'NAME_COLUMN'}
      })
    end

    it "defaults to string" do
      expect(config.field_types).to eq({
          'name' => 'string'
      })
    end
  end

  it "supports integers" do
    allow(config).to receive(:file_config).and_return([{'name' => 'one.csv'}])
    allow(config).to receive(:dictionary).and_return(
      IndifferentHash.new count:
        {source:'COUNT_COLUMN', type: 'integer'}
    )
    expect(config.field_types).to eq({'count' => 'integer'})
  end

  context "with float type" do
    it "sets float mapping" do
      allow(config).to receive(:file_config).and_return([{'name' => 'one.csv'}])
      allow(config).to receive(:dictionary).and_return(
        IndifferentHash.new percent:
           {source:'PERCENT_COLUMN', type: 'float'}
      )
      expect(config.field_types).to eq({'percent' => 'float'})
    end

    it "can be excluded" do
      allow(config).to receive(:dictionary).and_return(
        IndifferentHash.new id: {source:'ID', type: 'integer'},
          percent: {source:'PERCENT', type: 'float'}
      )
      allow(config).to receive(:file_config).and_return([
        IndifferentHash.new({ name:'one.csv', only: ['id'] })
      ])
      expect(config.field_types).to eq({'id' => 'integer'})
    end

    it "can be nested" do
      allow(config).to receive(:dictionary).and_return(
        IndifferentHash.new id: {source:'ID', type: 'integer'},
          percent: {source:'PERCENT', type: 'float'}
      )
      allow(config).to receive(:file_config).and_return([
        IndifferentHash.new({name:'one.csv',
            only: ['id']}),
        IndifferentHash.new({name:'two.csv',
            nest: {key: '2012', contents: ['percent']}})
      ])
      expect(config.field_types).to eq({
          'id' => 'integer',
          '2012.percent' => 'float'
      })
    end
  end

  context "with boolean type" do
    it "sets boolean mapping" do
      allow(config).to receive(:file_config).and_return([{'name' => 'one.csv'}])
      allow(config).to receive(:dictionary).and_return(
        IndifferentHash.new resident:
           {source:'RES_COLUMN', type: 'boolean'}
      )
      expect(config.field_types).to eq({'resident' => 'boolean'})
    end
  end

  it "supports special case for location fields as nil" do
    # special case for location in create_index
    allow(config).to receive(:dictionary).and_return(
      IndifferentHash.new 'location.lat': {source:'LAT_COLUMN'},
                          'location.lon': {source:'LON_COLUMN'}

    )
    expect(config.field_types).to eq({})
  end
end
