require_relative 'config'

module DataMagic
  module QueryBuilder
    class << self
      # Creates query from parameters passed into endpoint
      def from_params(params)
        squery = Stretchy.query(type: 'document')
        squery = handle_pagination(squery, params)
        squery = handle_boolean_conditions(squery, params)
        squery = handle_location(squery, params)
      end

      protected
      # Handles query pagination
      def handle_pagination(squery, params)
        page = params[:page] || 0
        per_page = params[:per_page] || Config.page_size
        squery = squery.page(page, per_page: per_page)
        params.delete(:page)
        params.delete(:per_page)
        squery
      end

      # Handles booleans and remaining equals variables
      def handle_boolean_conditions(squery, params)
        params.each do |field, value|
          match = /(.*)__(gt|lt|gte|lte)\z/.match(field)  #regex captures special boolean conditions >, >=, <, <=
          squery = if match
            var_name, operator = match.captures
            send(operator, squery, var_name, value)
          else
            squery.where(field: value)
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
      def handle_location(squery, params)
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