require 'spec_helper'
require 'data_magic'

describe "calculated columns" do

  before :example do
    DataMagic.destroy
    ENV['DATA_PATH'] = data_path
  end
  after :example do
    DataMagic.destroy
  end

  describe "combine into float" do
    let(:data_path) { "./spec/fixtures/schools" }
    it "can combine two columns" do
      DataMagic.config = DataMagic::Config.new
      DataMagic.import_with_dictionary
      result = DataMagic.search({}, fields: ['id', 'completion.rate.overall'])
      results = result['results'].sort_by { |hash| hash['id'] }
      expect(results[0]).to eq('id' => 1, 'completion.rate.overall' => 0.16)
      expect(results[1]).to eq('id' => 2, 'completion.rate.overall' => 0.62)
      expect(results[2]).to eq('id' => 3, 'completion.rate.overall' => nil)
      expect(results[3]).to eq('id' => 4, 'completion.rate.overall' => nil)
      expect(results[4]).to eq('id' => 5, 'completion.rate.overall' => 0.91)
    end
  end

  describe "combine into boolean" do
    let(:data_path) { "./spec/fixtures/calculated_columns" }
    it "can combine multiple columns" do
      DataMagic.config = DataMagic::Config.new
      DataMagic.import_with_dictionary
      result = DataMagic.search({}, fields: %w(id summarybool))
      results = result['results'].sort_by { |hash| hash['id'] }
      expect(results[0]).to eq('id' => 1, 'summarybool' => true)
      expect(results[1]).to eq('id' => 2, 'summarybool' => false)
      expect(results[2]).to eq('id' => 3, 'summarybool' => true)
    end
  end
end
