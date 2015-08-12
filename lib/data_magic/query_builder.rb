module DataMagic
  module QueryBuilder
    class << self
      # Creates query from parameters passed into endpoint
      def from_params(params, options, config)
        per_page = params.delete(:per_page) || config.page_size
        page = params.delete(:page) || 0
        query_hash = {
          from:   page * per_page,
          size:   per_page
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
        squery = search_fields_and_ranges(squery, params)
      end

      def get_restrict_fields(options)
        options[:fields].map { |field| field.to_s }
      end

      def get_sort_order(options)
        key, value = options[:sort].split(':')
        return { key => { order: value } }
      end

      RANGE_OPS = {
        gt:  :min,
        gte: :min,
        lt:  :max,
        lte: :max
      }

      def search_fields_and_ranges(squery, params)
        ranges = {}
        params.each do |field, value|
          match = /([-\w\.]*)__(gt|lt|gte|lte|ne)\z/.match(field)  #regex captures special boolean conditions >, >=, <, <=
          if match
            var_name, operator = match.captures.map(&:to_sym)
            if operator == :ne
              squery = squery.where.not(var_name => value)
            else
              ranges[var_name] = {} if !ranges.has_key?(var_name)
              # NOTE: we assume that range queries will be numeric, and not
              # dates (for now)
              ranges[var_name][RANGE_OPS[operator]] = value.to_f
              if operator == :gt or operator == :lt
                ex_sym = ("exclusive_" + RANGE_OPS[operator].to_s).to_sym
                ranges[var_name][ex_sym] = true
              end
            end
          else
            squery = squery.where(field => value)
          end
        end

        ranges.each {|var_name, range_args| squery = squery.range(var_name, range_args) }
        squery
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
