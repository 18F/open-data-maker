require 'spec_helper'
require 'data_magic'

describe "DataMagic intuitive search" do

  before :example do
    DataMagic.destroy
    ENV['DATA_PATH'] = './spec/fixtures/school_names'
    DataMagic.init(load_now: true)
  end
  after :example do
    DataMagic.destroy
  end

  RSpec.configure do |c|
    c.alias_it_should_behave_like_to :it_correctly, 'correctly:'
  end

  let(:expected_meta) {{"metadata"=>{"total"=>1, "page"=>0, "per_page"=>20}}}
  let(:expected_match) { "" }
  let(:response) {  DataMagic.search({'school.name' => subject}, fields:['school.name'])
 }

  shared_examples "finds" do
    it "correct results " do
      expect(response['results']
              .map { |i| i['school.name'] }
              .sort )
              .to eql expected_match
    end
    it "correct metadata" do
      expect(response.reject { |k, _| k == 'results' }).to eql expected_meta
    end
  end

  context "for exact match" do
    subject { 'New York University' }
    let(:expected_match) { ['New York University'] }
    it_correctly "finds"
  end
  context "for exact match (case insensitive)" do
    subject { 'new YORK UniverSity' }
    let(:expected_match) { ['New York University'] }
    it_correctly "finds"
  end

  context "for exact match (case insensitive)" do
    subject { 'new YORK UniverSity' }
    let(:expected_match) { ['New York University'] }
    it_correctly "finds"
  end

  context "by prefix" do
    subject { 'Still' }
    let(:expected_match) { ['Stillman College'] }
    it_correctly "finds"
  end

  context "by prefix (case insensitive)" do
    subject { 'still' }
    let(:expected_match) { ['Stillman College'] }
    it_correctly "finds"
  end

  context "by prefix in the middle of the name" do
    subject { 'Phoenix' }
    let(:expected_meta) {{"metadata"=>{"total"=>3, "page"=>0, "per_page"=>20}}}
    let(:expected_match) { ['Phoenix College',
                            'University of Phoenix-Online Campus',
                            "University of Phoenix-Phoenix Campus"] }
    it_correctly "finds"
  end

  context "with words in the wrong order" do
    subject { 'University New York' }
    let(:expected_match) { ['New York University'] }
    it_correctly "finds"
  end

  context "partial word after dash" do
    subject { 'berk' }
    let(:expected_meta) {{"metadata"=>{"total"=>3, "page"=>0, "per_page"=>20}}}
    let(:expected_match) { ['Berk Trade and Business School',
                            'Berklee College of Music',
                            'University of California-Berkeley'] }
    it_correctly "finds"
  end

  context "words separated by dash" do
    subject { 'phoenix online' }
    let(:expected_match) { ['University of Phoenix-Online Campus'] }
    it_correctly "finds"
  end

  # TO DO
  # "pheonix" (mis-spelling) should probably work
  # "phoenix college" should also probably return "university of phoenix" --- since college is a synonym for unversity

end
