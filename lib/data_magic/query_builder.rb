module DataMagic
  module QueryBuilder
    class << self
      # Creates query from parameters passed into endpoint
      def from_params(params, options, config)
        query_hash = {
          from:   params.delete(:page) || 0,
          size:   params.delete(:per_page) || config.page_size,
        }
        query_hash[:query] = generate_squery(params, config).to_search
        query_hash[:fields] = get_restrict_fields(options) if options[:fields] && !options[:fields].empty?
        query_hash[:sort] = get_sort_order(options) if options[:sort]
        query_hash
      end

      private

      def generate_squery(params, config)
        squery = Stretchy.query(type: 'document')
        squery = search_location(squery, params)
        squery = search_boolean_conditions(squery, params)
      end

      def get_restrict_fields(options)
        options[:fields].map { |field| field.to_s }
      end

      def get_sort_order(options)
        key, value = options[:sort].split(':')
        return { key => { order: value } }
      end

      def search_boolean_conditions(squery, params)
        params.each do |field, value|
          match = /(.*)__(gt|lt|gte|lte)\z/.match(field)  #regex captures special boolean conditions >, >=, <, <=
          squery = if match
            var_name, operator = match.captures
            send(operator, squery, var_name, value)
          else
            squery.where(field => value)
          end
        end
        squery
      end

      def gt(query, var_name, value)
        query.range(var_name, exclusive_min: value)
      end

      def lt(query, var_name, value)
        query.range(var_name, exclusive_max: value)
      end

      def gte(query, var_name, value)
        query.range(var_name, min: value)
      end

      def lte(query, var_name, value)
        query.range(var_name, max: value)
      end

      # Handles location (currently only uses SFO location)
      def search_location(squery, params)
        distance = params[:distance]
        if distance && !distance.empty?
          location = { lat: 37.615223, lon:-122.389977 } #sfo
          squery = squery.geo('location', distance: distance, lat: location[:lat], lng: location[:lon])
          params.delete(:distance)
          params.delete(:zip)
        end
        squery
      end

    end

  end
end
