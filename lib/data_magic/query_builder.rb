module DataMagic
  module QueryBuilder
    class << self
      # Creates query from parameters passed into endpoint
      def from_params(params, options, config)
        per_page = options[:per_page] || config.page_size || DataMagic::DEFAULT_PAGE_SIZE
        page = options[:page] || 0
        query_hash = {
          _source: {
            exclude: ["_*"]
          },
          from:   page * per_page.to_i,
          size:   per_page.to_i
        }
        query_hash[:query] = generate_squery(params, options, config).to_search
        if options[:add_aggregations]
          query_hash.merge! add_aggregations(params, options, config)
        end

        query_hash[:fields] = get_restrict_fields(options) if options[:fields] && !options[:fields].empty?
        query_hash[:sort] = get_sort_order(options[:sort]) if options[:sort] && !options[:sort].empty?
        query_hash
      end

      private

      def generate_squery(params, options, config)
        squery = Stretchy.query(type: 'document')
        squery = search_location(squery, options)
        search_fields_and_ranges(squery, params, config)
      end

      def add_aggregations(params, options, config)
        # Wrapper for Stretchy aggregation clause builder (which wraps ElasticSearch (ES) :aggs parameter)
        # Extracts all extended_stats aggregations from ES, to be filtered later
        # Is a no-op if no fields are specified, or none of them are numeric

        agg_hash = options[:fields].inject({}) do |memo, f|
          if config.column_field_types[f.to_s] && ["integer", "float"].include?(config.column_field_types[f.to_s])
            memo[f.to_s] = { "extended_stats" => { "field" => f.to_s } }
          end
          memo
        end

        agg_hash != {} ? { "aggs" => agg_hash } : {}
      end

      def get_restrict_fields(options)
        options[:fields].map(&:to_s)
      end

      # @description turns a string like "state,population:desc" into [{'state' => {order: 'asc'}},{ "population" => {order: "desc"} }]
      # @param [String] sort_param
      # @return [Array]
      def get_sort_order(sort_param)
        sort_param.to_s.scan(/(\w+[\.\w]*):?(\w*)/).map do |field_name, direction|
          direction = 'asc' if direction.empty?
          { field_name => { order: direction } }
        end
      end

      def to_number(value)
        value =~ /\./ ? value.to_f : value.to_i
      end

      def include_name_query(squery, field, value)
        value = value.split(' ').map { |word| "#{word}*"}.join(' ')
        squery = squery.match.query(
          # we store lowercase name in field with prefix _
          "wildcard": { "_#{field}" => { "value": value.downcase } }
        )
      end

      def search_fields_and_ranges(squery, params, config)
        params.each do |field, value|
          if config.field_type(field) == "name"
            squery = include_name_query(squery, field, value)
          elsif match = /(.+)__(range|ne|not)\z/.match(field)
            var_name, operator = match.captures.map(&:to_sym)
            if operator == :ne or operator == :not  # field negation
              squery = squery.where.not(var_name => value)
            else  # field range
              squery = squery.filter(
                or: build_ranges(var_name, value.split(','))
              )
            end
          else # field equality
            squery = squery.where(field => value)
          end
        end
        squery
      end

      def build_ranges(var_name, range_strings)
        range_strings.map do |range|
          min, max = range.split('..')
          values = {}
          values[:gte] = to_number(min) unless min.empty?
          values[:lte] = to_number(max) if max
          {
            range: { var_name => values }
          }
        end
      end

      # Handles location (currently only uses SFO location)
      def search_location(squery, options)
        distance = options[:distance]
        location = Zipcode.latlon(options[:zip])

        if distance && !distance.empty?
          # default to miles if no distance given
          unit = distance[-2..-1]
          distance = "#{distance}mi" if unit != "km" and unit != "mi"

          squery = squery.geo('location', distance: distance, lat: location[:lat], lng: location[:lon])
        end
        squery
      end

    end

  end

end
