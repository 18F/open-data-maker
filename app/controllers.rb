# Main front page
OpenDataMaker::App.controllers do
  get :index do
    render :home, layout: true, locals: {
      'title' => 'Open Data Maker',
      'endpoints' => DataMagic.config.api_endpoint_names,
      'examples' => DataMagic.config.examples,
      'categories' => DataMagic.config.categories.to_json
    }
  end

  get :category, :with => :id do
    category_entry = DataMagic.config.category_by_id(params[:id])
    render :category, layout: true, locals: {
      'title' => 'Open Data Maker',
      'category_entry' => category_entry.to_json,
      'field_details' => category_entry['field_details'].to_json
    }
  end
end

CACHE_TTL = 300

# All API requests are prefixed by the API version
# in this case, "v1" - e.g. "/vi/endpoints" etc.
OpenDataMaker::App.controllers :v1 do
  before do
    content_type :json
    headers 'Access-Control-Allow-Origin' => '*',
            'Access-Control-Allow-Methods' => ['GET'],
            'Surrogate-Control' => "max-age=#{CACHE_TTL}"
    cache_control :public, max_age: CACHE_TTL
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
    options = get_search_args_from_params(params)
    endpoint = options[:endpoint]
    content_type options[:format].to_sym if options[:format]
    DataMagic.logger.debug "-----> APP GET #{params.inspect}"

    unless DataMagic.config.api_endpoints.keys.include? endpoint
      halt 404, {
        error: 404,
        message: "#{endpoint} not found. Available endpoints: #{DataMagic.config.api_endpoints.keys.join(',')}"
      }.to_json
    end

    data = DataMagic.search(params, options)
    halt 400, data.to_json if data.key?(:errors)

    if content_type == :csv
      output_data_as_csv(data['results'])
    else
      data.to_json
    end
  end
end

# TODO: Use of non-underscore-prefixed option parameters is still
# supported but deprecated, and should be removed at some point soon -
# see comment in method body
def get_search_args_from_params(params)
  options = {}
  %w(sort fields zip distance page per_page debug).each do |opt|
    options[opt.to_sym] = params.delete("_#{opt}")
    # TODO: remove next line to end support for un-prefixed option parameters
    options[opt.to_sym] ||= params.delete(opt)
  end
  options[:endpoint] = params.delete("endpoint") # these two params are
  options[:format]   = params.delete("format")   # supplied by Padrino
  options[:fields]   = (options[:fields]   || "").split(',')
  options
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
