require 'spec_helper'
require 'data_magic'
require 'hashie'

describe DataMagic::QueryBuilder do

  before :example do
    DataMagic.destroy
    ENV['DATA_PATH'] = './spec/fixtures/minimal'
    DataMagic.config = DataMagic::Config.new
  end

  after :example do
    DataMagic.destroy
  end

  RSpec.configure do |c|
    c.alias_it_should_behave_like_to :it_correctly, 'correctly:'
  end

  let(:expected_meta) { { from:0, size:20 } }
  let(:options) { { } }
  let(:query_hash) { DataMagic::QueryBuilder.from_params(subject, options, DataMagic.config) }

  shared_examples "builds a query" do

    it "with a query section" do
      expect(query_hash[:query]).to eql expected_query
    end
    it "with query metadata" do
      expect(query_hash.reject {|k,v| k == :query }).to eql expected_meta
    end
  end

  describe "can issue a blank query" do
    subject { { } }
    let(:expected_query) { { match_all: {} } }
    it_correctly "builds a query"
  end

  describe "can exact match on a field" do
    subject { {zip: "35762"} }
    let(:expected_query) { { match: {"zip" => {query: "35762"} } } }
    it_correctly "builds a query"
  end

  describe "can search within a location" do
    subject { { zip: "94132", distance: "30mi" } }
    let(:expected_query) do {
      filtered: {
        query: { match_all: {} },
        filter: {
          geo_distance: {
            distance: "30mi",
            "location" => { lat: 37.615223, lon: -122.389977 }
      } } } }
    end
    it_correctly "builds a query"
  end

  describe "can handle pagination" do
    subject { { page: 3, per_page: 11 } }
    let(:expected_query) { { match_all: {} } }
    let(:expected_meta)  { { from: 3, size: 11 } }
    it_correctly "builds a query"
  end

  describe "can specify sort order" do
    subject { { } }
    let(:options) { { sort: "population:asc" } }
    let(:expected_query) { { match_all: {} } }
    let(:expected_meta)  { { from: 0, size: 20, sort: { "population" => {order: "asc"} } } }
    it_correctly "builds a query"
  end

  describe "can search in an inclusive numeric range" do
    context "that is open-ended" do
      subject { { age__gte: 10 } }
      let(:expected_query) do {
        filtered: {
          query: { match_all: {} },
          filter: {
            range: {
              age: {
                gte: 10
        } } } } }
      end
      it_correctly "builds a query"
    end

    context "that is closed" do
      subject { { age__gte: 10, age__lte: 20  } }
      let(:expected_query) do {
        filtered: {
          query: { match_all: {} },
          filter: { range: { age: { gte: 10, lte: 20 } } }
        }
      }
      end
      it_correctly "builds a query"
    end
  end

  describe "can search in an exclusive numeric range" do
    context "that is open-ended" do
      subject { { age__gt: 10 } }
      let(:expected_query) do {
        filtered: {
          query: { match_all: {} },
          filter: { range: { age: { gt: 10 } } }
        }
      }
      end
      it_correctly "builds a query"
    end

    context "that is closed" do
      subject { { age__gt: 10, age__lt: 20  } }
      let(:expected_query) do {
        filtered: {
          query: { match_all: {} },
          filter: { range: { age: { gt: 10, lt: 20 } } }
        }
      }
      end
      it_correctly "builds a query"
    end
  end

  describe "can search with multiple ranges" do
    subject { { age__gt: 10, age__lt: 20, size__lte: 15  } }
    let(:expected_query) do {
      filtered: {
        query: { match_all: {} },
        filter: {
          and: [
            { range: { age: { gt: 10, lt: 20 } } },
            { range: { size:  { lte: 15 } } }
          ]
      } } }
    end
    it_correctly "builds a query"
  end
end
