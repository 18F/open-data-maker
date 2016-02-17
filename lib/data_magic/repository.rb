module DataMagic
  class Repository
    attr_reader :client, :document

    def initialize(client, document)
      @client = client
      @document = document
    end

    def save
      @skipped = false
      if client.creating?
        create
      else
        update
      end
    end

    def skipped?
      @skipped
    end

    def save
      if client.creating?
        create
      else
        update
      end
    end

    private

    def update
      if client.allow_skips?
        update_with_rescue
      else
        update_without_rescue
      end
    end

    def create
      client.index({
        index: client.index_name,
        id: document.id,
        type: 'document',
        body: document.data
      })
    end

    def update_without_rescue
      client.update({
        index: client.index_name,
        id: document.id,
        type: 'document',
        body: {doc: document.data}
      })
    end

    def update_with_rescue
      update_without_rescue
    rescue Elasticsearch::Transport::Transport::Errors::NotFound
      @skipped = true
    end
  end
end
