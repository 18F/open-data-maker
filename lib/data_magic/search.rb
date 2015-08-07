require_relative 'config'

module DataMagic


  # thin layer on elasticsearch query
  def self.search(terms, options = {})
    terms = IndifferentHash.new(terms)
    options[:fields] ||= []
    fields = options[:fields].map { |field| field.to_s }
    index_name = index_name_from_options(options)
    logger.info "search terms:#{terms.inspect}"
    squery = Stretchy.query

    distance = terms[:distance]
    if distance && !distance.empty?
      location = { lat: 37.615223, lon:-122.389977 } #sfo
      squery = squery.geo('location', distance: distance, lat: location[:lat], lng: location[:lon])
      terms.delete(:distance)
      terms.delete(:zip)
    end

    page = terms[:page] || 0
    per_page = terms[:per_page] || config.page_size

    terms.delete(:page)
    terms.delete(:per_page)

    # logger.info "--> terms: #{terms.inspect}"
    squery = squery.where(terms) unless terms.empty?

    full_query = {
      index: index_name,
      type: 'document',
      body: {
        from: page,
        size: per_page,
        query: squery.to_search
      }
    }
    if not fields.empty?
      full_query[:body][:fields] = fields
    end

    logger.info "===========> full_query:#{full_query.inspect}"

    result = client.search full_query
    logger.info "result: #{result.inspect}"
    hits = result["hits"]
    total = hits["total"]
    results = []
    if fields.empty?
      # we're getting the whole document and we can find in _source
      results = hits["hits"].map {|hit| hit["_source"]}
    else
      # we're getting a subset of fields...
      results = hits["hits"].map do |hit|
        found = hit["fields"]
        # each result looks like this:
        # {"city"=>["Springfield"], "address"=>["742 Evergreen Terrace"]}

        found.keys.each { |key| found[key] = found[key][0] }
        # now it should look like this:
        # {"city"=>"Springfield", "address"=>"742 Evergreen Terrace
        found
      end
    end

    # assemble a simpler json document to return
    {
      "total" => total,
      "page" => page,
      "per_page" => per_page,
      "results" => 	results
    }
  end







end # DataMagic
