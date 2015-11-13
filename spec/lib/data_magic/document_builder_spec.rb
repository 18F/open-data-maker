require 'spec_helper'
require 'data_magic'
require 'hashie'

describe DataMagic::DocumentBuilder do
  let(:config)     { DataMagic::Config.new(load_datayaml: false) }
  let(:fields)     { {} }
  let(:options)    { {} }
  let(:additional) { {} }
  let(:document)   { DataMagic::DocumentBuilder.parse_row(subject, fields, config, options, additional) }

  RSpec.configure do |c|
    c.alias_it_should_behave_like_to :it_correctly, 'correctly:'
  end

  shared_examples "creates a document" do
    it "with fields" do
      expect(document).to eql expected_document
    end
  end

  context "with no field mapping" do
    describe "strings" do
      subject { { city: 'New York', state: 'NY' } }
      let(:expected_document) { { 'city' => 'New York', 'state' => 'NY' } }
      it_correctly "creates a document"
    end
  end
  context "with type mapping" do
    describe "integer" do
      before do
        allow(config).to receive(:column_field_types).and_return(size: 'integer')
      end
      subject { { size: '45' } }
      let(:expected_document) { { 'size' => 45 } }
      it_correctly "creates a document"
    end

    describe "with name type" do
      before do
        config.dictionary = { city: { source: 'CITY', type: 'name' } }
      end
      subject { { city: 'New York' } }
      let(:expected_document) { { 'city' => 'New York', '_city' => 'new york' } }
      it_correctly "creates a document"
    end

    describe "multiple types" do
      before do
        allow(config).to receive(:column_field_types).and_return(
          population: 'integer', elevation: 'float')
      end
      subject { { name: 'Smithville', population: '45', elevation: '20.5' } }
      let(:expected_document) do
        { 'name' => 'Smithville',
          'population' => 45,
          'elevation' => 20.5 }
      end
      it_correctly "creates a document"
    end

    describe "float expressions" do
      before do
        allow(config).to receive(:column_field_types).and_return(
          one: 'float', two: 'float', one_or_two: 'float')
        allow(config).to receive(:dictionary).and_return(
          one_or_two: {
            calculate: 'one or two',
            type: 'float',
            description: 'something'
          })
      end
      context "with second value NULL" do
        subject { { one: '0.12', two: 'NULL' } }
        let(:expected_document) { { 'one' => 0.12, 'two' => nil, 'one_or_two' => 0.12 } }
        it "reports calculated fields" do
          expect(
            DataMagic::DocumentBuilder.calculated_fields(subject, config)
          ).to eq('one_or_two' => 0.12)
        end
        it_correctly "creates a document"
      end

      context "with first value NULL" do
        subject { { one: 'NULL', two: '0.45' } }
        let(:expected_document) { { 'one' => nil, 'two' => 0.45, 'one_or_two' => 0.45 } }
        it_correctly "creates a document"
      end

      context "and zero evaluates to false" do
        subject { { one: '0.0', two: '0.45' } }
        let(:expected_document) { { 'one' => 0.0, 'two' => 0.45, 'one_or_two' => 0.45 } }
        it_correctly "creates a document"
      end

      context "and zero evaluates to false and stays zero" do
        subject { { one: '0.0', two: '0.0' } }
        let(:expected_document) { { 'one' => 0.0, 'two' => 0.0, 'one_or_two' => 0.0 } }
        it_correctly "creates a document"
      end
    end
  end

  context "with column name mapping" do
    before do
      config.dictionary = { name: 'NAME', state: 'STABBR' }
    end
    let(:fields) { config.field_mapping }
    context "with second value NULL" do
      subject { { NAME: 'foo', STABBR: 'MA' } }
      let(:expected_document) { { 'name' => 'foo', 'state' => 'MA' } }
      it_correctly "creates a document"
    end
  end

  describe "integer expressions" do
    before do
      allow(config).to receive(:column_field_types).and_return(
        one: 'integer', two: 'integer', one_or_two: 'integer')
      allow(config).to receive(:dictionary).and_return(
        one_or_two: {
          calculate: 'one or two',
          type: 'integer',
          description: 'a whole number'
        })
    end
    context "zero evaluates to false" do
      subject { { one: '0', two: '4' } }
      let(:expected_document) { { 'one' => 0, 'two' => 4, 'one_or_two' => 4 } }
      it_correctly "creates a document"
    end

    context "zero evaluates to false and stays zero" do
      subject { { one: '0', two: '0' } }
      let(:expected_document) { { 'one' => 0, 'two' => 0, 'one_or_two' => 0 } }
      it_correctly "creates a document"
    end
  end
  context "with options[:only]" do
    before do
      config.dictionary = { id: 'ID',
                            state: 'STABBR',
                            city: {
                              source: 'CITY',
                              type: 'name'
                            }
                          }
    end
    let(:fields) { config.field_mapping }

    context "specify two vanilla columns" do
      let(:options) { { only: %w(id state) } }
      subject { { ID: 'ABC', STABBR: 'NY', CITY: 'New York' } }
      let(:expected_document) { { 'id' => 'ABC', 'state' => 'NY' } }
      it_correctly "creates a document"
    end

    context "specify name column" do
      let(:options) { { only: %w(city) } }
      subject { { ID: 'ABC', STABBR: 'NY', CITY: 'New York' } }
      let(:expected_document) { { 'city' => 'New York', '_city' => 'new york' } }
      it_correctly "creates a document"
    end
  end
end
