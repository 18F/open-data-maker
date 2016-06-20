require 'spec_helper'
require 'data_magic'
require 'fixtures/data.rb'

describe DataMagic do
  it "cleans up after itself" do
    DataMagic.init(load_now: true)
    DataMagic.destroy
    DataMagic.logger.info "just destroyed"
    #expect(DataMagic.client.indices.get(index: '_all')).to be_empty
  end

  describe '.es_field_types' do
    it 'returns the given fields with their specified type' do
      expect(described_class.es_field_types({ 'state' => 'string', land_area: 'string' }))
      .to eq("state" => { :type => "string" },
          :land_area => { :type => "string" })
    end

    context 'with custom type "literal"' do
      it 'returns string type with :index of "not_analyzed"' do
        expect(described_class.es_field_types({ 'state' => 'string', 'name' => 'literal' }))
        .to eq({"state"=>{:type=>"string"}, "name"=>{:type=>"string", :index=>"not_analyzed"}})
      end
    end

    context 'with type "date"' do
      it 'returns the date field with date type in default format' do
        expect(described_class.es_field_types({ 'date' => 'date' }))
        .to eq({"date"=>{:type=>"date",:format=>"yyyy-MM-dd"}})                                       
      end
    end

  end

end
