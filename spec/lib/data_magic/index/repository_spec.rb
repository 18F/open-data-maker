require 'spec_helper'
require 'data_magic'

describe DataMagic::Index::Repository do
  let(:repository) { DataMagic::Index::Repository.new(super_client, document) }

  let(:super_client) { double('super client', index_name: 'index') }
  let(:document) { double('document', {id: 'id', data: 'data'}) }

  context 'when super client is creating' do
    before do
      allow(super_client).to receive(:creating?).and_return(true)
      allow(super_client).to receive(:index)
    end

    it '#save creates an index' do
      expect(super_client).to receive(:index).with({
        index: 'index',
        id: 'id',
        type: 'document',
        body: 'data'
      })
      repository.save
    end

    it '#save will not be skipped when successful' do
      repository.save
      expect(repository.skipped?).to be_falsey
    end
  end

  context 'when super client is not creating' do
    before do
      allow(super_client).to receive(:creating?).and_return(false)
      allow(super_client).to receive(:allow_skips?)
      allow(super_client).to receive(:update)
    end

    it '#save updates an index' do
      expect(super_client).to receive(:update).with({
        index: 'index',
        id: 'id',
        type: 'document',
        body: {doc: 'data'}
      })
      repository.save
    end

    it '#save will not be skipped when successful' do
      repository.save
      expect(repository.skipped?).to be_falsey
    end
  end

  context 'when super client is not creating, not skipping and an error is raised' do
    before do
      allow(super_client).to receive(:creating?).and_return(false)
      allow(super_client).to receive(:allow_skips?).and_return(false)
    end

    it '#save raises an error' do
      allow(super_client).to receive(:update).and_raise(Elasticsearch::Transport::Transport::Errors::NotFound)
      expect {
        repository.save
      }.to raise_error(Elasticsearch::Transport::Transport::Errors::NotFound)
    end
  end

  context 'when super client is not creating, skipping and an error is raised' do
    before do
      allow(super_client).to receive(:creating?).and_return(false)
      allow(super_client).to receive(:allow_skips?).and_return(true)
    end

    it '#save marks the repository as skipped' do
      allow(super_client).to receive(:update).and_raise(Elasticsearch::Transport::Transport::Errors::NotFound)
      expect {
        repository.save
      }.not_to raise_error
      expect(repository.skipped?).to eq(true)
    end
  end
end
