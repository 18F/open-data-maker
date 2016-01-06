require './lib/expression/expression'

module DataMagic
  module DocumentBuilder
    class << self
      def logger
        DataMagic::Config.logger
      end

      # build a nested json document from a csv row
      # row: a hash  { column_name => value }
      #      where all column_names and values are strings
      # fields: column_name => field_name
      # config: DataMagic.Config instance for dictionary, column types, NULL
      def build(row, fields, config, options={}, additional=nil)
        field_values = nil
        csv_row = row.to_hash
        csv_row = map_field_types(csv_row, config)
        puts "csv_row: #{csv_row}"
        if fields.empty?
          field_values = csv_row
        else
          field_values = map_field_names(csv_row, fields, options)
        end
        field_values = field_values.merge(calculated_fields(csv_row, config))

        field_values.merge!(lowercase_columns(field_values, config.column_field_types))
        field_values.merge!(additional) if additional
        doc = NestedHash.new.add(field_values)
        doc = parse_nested(doc, options) if options[:nest]
        doc = select_only_fields(doc, options[:only]) unless options[:only].nil?
        doc
      end

      private

      def calculated_fields(row, config)
        result = {}
        config.calculated_field_list.each do |name|
          result[name] = calculate(name, row, config.dictionary)
        end
        result
      end

      # row: a hash  (keys may be strings or symbols)
      # config: a config object
      # returns a hash where values have been coerced to the new type
      def map_field_types(row, config)
        valid_types = config.valid_types
        field_types = config.csv_column_field_types || {}
        null_value = config.null_value || null_value = 'NULL'
        mapped = {}
        row.each do |key, value|
          if value == null_value
            mapped[key] = nil
          else
            type = field_types[key.to_sym] || field_types[key.to_s]
            if valid_types.include? type
              mapped[key] = fix_field_type(type, value, key)
            else
              fail InvalidDictionary, "unexpected type '#{type.inspect}' for field '#{key}'"
            end
          end
        end
        mapped
      end

      def lowercase_columns(row, field_types = {})
        new_columns = {}
        row.each do |key, value|
          type = field_types[key.to_sym] || field_types[key.to_s]
          new_columns["_#{key}"] = value.downcase if type == "name" || type == "autocomplete"
        end
        new_columns
      end

      def parse_nested(document, options)
        new_doc = {}
        nest_options = options[:nest]
        if nest_options
          key = nest_options['key']
          new_doc[key] = {}
          new_doc['id'] = document['id'] unless document['id'].nil?
          nest_options['contents'].each do |item_key|
            new_doc[key][item_key] = document[item_key]
          end
        end
        new_doc
      end

      def fix_field_type(type, value, key=nil)
        return value if value.nil?

        new_value = case type
                    when "float"
                      value.to_f
                    when "integer"
                      value.to_i
                    when "lowercase_name"
                      value.to_s.downcase
                    when 'boolean'
                      parse_boolean(value)
                    else # "string"
                      value.to_s
        end
        new_value = value.to_f if key and key.to_s.include? "location"
        new_value
      end

      def parse_boolean(value)
        case value
        when "true"
          true
        when "false"
          false
        when 0
          false
        else
          !!value
        end
      end

      # currently we just support 'or' operations on two columns
      def calculate(field_name, row, dictionary)
        item = dictionary[field_name.to_s] || dictionary[field_name.to_sym]
        fail "calculate: field not found in dictionary #{field_name.inspect}" if item.nil?
        expr = item['calculate'] || item[:calculate]
        fail ArgumentError, "expected to calculate #{field_name}" if expr.nil?
        vars = {}
        e = Expression.new(expr)
        e.variables.each do |name|
          vars[name] = fix_field_type(item['type'] || item[:type],
                                      row[name.to_sym])
        end
        e.evaluate(vars)
      end

      # row: a hash  (keys may be strings or symbols)
      # new_fields: hash current_name : new_name
      # returns a hash (which may be a subset of row) where keys are new_name
      #         with value of corresponding row[current_name]
      def map_field_names(row, new_fields, options = {})
        puts "--- map_field_names"
        mapped = {}
        row.each do |key, value|
          fail ArgumentError, "column header missing for: #{value}" if key.nil?
          new_key = new_fields[key.to_sym] || new_fields[key.to_s]
          if new_key
            value = value.to_f if new_key.include? "location"
            mapped[new_key] = value
            puts "new_key: #{new_key}, value: #{value.inspect} #{value.class}"
          elsif options[:columns] == 'all'
            mapped[key] = value
            puts "key: #{key}, value: #{value.inspect} #{value.class}"
          end
        end
        puts "mapped: #{mapped}"
        mapped
      end

      # select top-level fields from a hash
      # if there are name types, also select _name
      # doc: hash with string keys
      # only_keys: array of keys
      def select_only_fields(doc, only_keys)
        doc = doc.select do |key, value|
          key = key.to_s
          # if key has _ prefix, select if key present without _
          key = key[1..-1] if key[0] == '_'
          only_keys.include?(key)
        end
      end

    end # class methods
  end # module QueryBuilder
end  # module DataMagic
