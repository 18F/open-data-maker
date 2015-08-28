# Main front page
OpenDataMaker::App.controllers do
  get :index do
    render :home, layout: true, locals: {
      'title' => 'Open Data Maker',
      'endpoints' => DataMagic.config.api_endpoint_names,
      'examples' => DataMagic.config.examples
    }
  end
end

# All API requests are prefixed by the API version
# in this case, "v1" - e.g. "/vi/endpoints" etc.
OpenDataMaker::App.controllers :v1 do
  before do
    content_type :json
    headers 'Access-Control-Allow-Origin' => '*',
            'Access-Control-Allow-Methods' => ['GET']
  end

  get :endpoints do
    endpoints = DataMagic.config.api_endpoints.keys.map do |key|
      {
        name: key,
        url: url_for(:v1, :index, endpoint: key)
      }
    end
    return { endpoints: endpoints }.to_json
  end

  get '/data.json' do
    data = DataMagic.config.data
    data.to_json
  end

  get :index, with: :endpoint, provides: [:json, :csv] do
    (endpoint, sort, fields, format) = get_search_args_from_params(params)
    content_type format.to_sym if format
    DataMagic.logger.debug "-----> APP GET #{params.inspect}"

    if not DataMagic.config.api_endpoints.keys.include? endpoint
      halt 404, {
        error: 404,
        message: "#{endpoint} not found. Available endpoints: #{DataMagic.config.api_endpoints.keys.join(',')}"
      }.to_json
    end

    data = DataMagic.search(params, sort: sort, api: endpoint, fields: fields)

    if format == 'csv'
      output_data_as_csv(data['results'])
    else
      data.to_json
    end
  end
end

def get_search_args_from_params(params)
  endpoint = params.delete("endpoint")
  sort = params.delete("sort")
  fields = (params.delete('fields') || "").split(',')
  format = params.delete('format')
  [endpoint, sort, fields, format]
end

def output_data_as_csv(results)
  # We assume all rows have the same keys
  if results.empty?
    ''
  else
    CSV.generate(force_quotes: true, headers: true) do |csv|
      results.each_with_index do |row, row_num|
        row = NestedHash.new(row).withdotkeys
        # make the order match data.yaml order
        output = DataMagic.config.field_types.each_with_object({}) do |(name, type), output|
          output[name] = row[name] unless row[name].nil?
          if name == "location"
            output["location.lat"] = row["location.lat"] unless row["location.lat"].nil?
            output["location.lon"] = row["location.lon"] unless row["location.lon"].nil?
          end
        end
        csv << output.keys if row_num == 0
        csv << output
      end
    end
  end
end
