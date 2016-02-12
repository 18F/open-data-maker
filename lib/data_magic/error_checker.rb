module DataMagic
  module ErrorChecker
    class << self
      def check(params, options, config)
        report_required_params_absent(options) +
          report_nonexistent_params(params, config) +
          report_nonexistent_operators(params) +
          report_nonexistent_fields(options[:fields], config) +
          report_bad_range_argument(params) +
          report_wrong_field_type(params, config) +
          report_wrong_zip(options) +
          report_distance_requires_zip(options)
      end

      private

      def report_required_params_absent(options)
        if options[:command] == 'stats' && options[:fields].length == 0
          [build_error(error: 'invalid_or_incomplete_parameters', input: options[:command])]
        else
          []
        end
      end

      def report_distance_requires_zip(params)
        # if distance, must have zip
        return [] if (params[:distance] && params[:zip]) || (!params[:distance])
        [build_error(
          error: 'distance_error'
        )]
      end

      def report_wrong_zip(params)
        return [] if !params[:zip] || Zipcode.valid?(params[:zip])
        [build_error(
          error: 'zipcode_error',
          parameter: :zip,
          input: params[:zip].to_s
        )]
      end

      def report_nonexistent_params(params, config)
        return [] unless config.dictionary_only_search?
        params.keys.reject { |p| config.field_type(strip_op(p)) }.
          map { |p| build_error(error: 'parameter_not_found', input: strip_op(p)) }
      end

      def report_nonexistent_operators(params)
        params.keys.select { |p| p =~ /__(\w+)$/ && $1 !~ /range|not|ne/i }.
          map do |p|
            (param, op) = p.match(/^(.*)__(\w+)$/).captures
            build_error(error: 'operator_not_found', parameter: param, input: op)
          end
      end

      def report_nonexistent_fields(fields, config)
        if fields && !fields.empty? && config.dictionary_only_search?
          fields.reject { |f| config.field_type(f.to_s) }.
            map { |f| build_error(error: 'field_not_found', input: f.to_s) }
        else
          []
        end
      end

      def report_bad_range_argument(params)
        ranges = params.select do |p,v|
          p =~ /__range$/ and
            v !~ / ^(\d+(\.\d+)?)? # optional starting number
                   \.\.           # range dots
                   (\d+(\.\d+)?)?  # optional ending number
                   (,(\d+(\.\d+)?)?\.\.(\d+(\.\d+)?)?)* # and more, with commas
                   $/x
        end
        ranges.map do |p,v|
          build_error(error: 'range_format_error', parameter: strip_op(p), input: v)
        end
      end

      def report_wrong_field_type(params, config)
        bad_fields = params.select do |p, v|
          next false if p =~ /__range$/
          param_type = config.field_type(strip_op(p))
          value_type = guess_value_type(v)
          (param_type == "float" && value_type != "float" && value_type != "integer") or
            (param_type == "integer" && value_type != "integer")
        end
        bad_fields.map do |p, v|
          build_error(error: 'parameter_type_error', parameter: p, input: v,
                      expected_type: config.field_type(strip_op(p)),
                      input_type: guess_value_type(v))
        end
      end

      def build_error(opts)
        opts[:message] =
          case opts[:error]
          when 'invalid_or_incomplete_parameters'
            "The command #{opts[:input]} requires a fields parameter."
          when 'parameter_not_found'
            "The input parameter '#{opts[:input]}' is not known in this dataset."
          when 'field_not_found'
            "The input field '#{opts[:input]}' (in the fields parameter) is not a field in this dataset."
          when 'operator_not_found'
            "The input operator '#{opts[:input]}' (appended to the parameter '#{opts[:parameter]}') is not known or supported. (Known operators: range, ne, not)"
          when 'parameter_type_error'
            "The parameter '#{opts[:parameter]}' expects a value of type #{opts[:expected_type]}, but received '#{opts[:input]}' which is a value of type #{opts[:input_type]}."
          when 'range_format_error'
            "The range '#{opts[:input]}' supplied to parameter '#{opts[:parameter]}' isn't in the correct format."
          when 'zipcode_error'
            "The provided zipcode, '#{opts[:input]}', is not valid."
          when 'distance_error'
            "Use of the 'distance' parameter also requires a 'zip' parameter."
          end
        opts
      end

      def guess_value_type(value)
        case value.to_s
        when /^-?\d+$/
          "integer"
        when /^(-?\d+,?)+$/ # list of integers
          "integer"
        when /^-?\d+\.\d+$/
          "float"
        else
          "string"
        end
      end

      def strip_op(param)
        param.sub(/__\w+$/, '')
      end
    end
  end
end
