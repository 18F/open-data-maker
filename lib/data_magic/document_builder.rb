require './lib/expression'

module DataMagic
  module DocumentBuilder
    class << self
      def logger
        DataMagic::Config.logger
      end
      # parse a row from a csv file, returns a nested document
      # row: a hash  { field => value } where all values are strings
      # fields: column_name => field_name
      # config: DataMagic.Config instance for dictionary, column types, NULL
      def parse_row(row, fields, config, options={}, additional=nil)
        row = csv_row = row.to_hash
        # logger.debug "row #{row.inspect[0..255]}"
        # logger.debug "fields #{fields.inspect[0..255]}"
        # logger.debug "column_field_types #{config.column_field_types.inspect[0..255]}"
        row = map_field_names(row, fields, config, options) unless fields.empty?
        row = row.merge(calculated_fields(csv_row, config))
        unless config.column_field_types.empty? && config.null_value.empty?
          row = map_field_types(row, config.valid_types,
                                 config.column_field_types,
                                 config.null_value)
        end
        row = row.merge(additional) if additional
        doc = NestedHash.new.add(row)
        doc = parse_nested(doc, options) if options[:nest]
        doc = select_only_fields(doc, options[:only]) unless options[:only].nil?
        #logger.debug "doc #{doc.inspect[0..255]}"
        doc
      end

      def calculated_fields(row, config)
        result = {}
        #logger.info "calculated_fields: #{config.calculated_field_list}"
        config.calculated_field_list.each do |name|
          result[name] = calculate(name, row, config.dictionary)
          #logger.info "#{name.inspect} #{result[name].inspect}"
        end
        result
      end
    private
      # row: a hash  (keys may be strings or symbols)
      # valid_types: an array of allowed types
      # field_types: hash field_name : type (float, integer, string)
      # returns a hash where values have been coerced to the new type
      def map_field_types(row, valid_types, field_types = {}, null_value = 'NULL')
        # logger.debug("map_field_types: #{valid_types.inspect} #{field_types.inspect}")
        # logger.debug("row: #{row.inspect}")
        mapped = {}
        row.each do |key, value|
          if value == null_value
            mapped[key] = nil
          else
            type = field_types[key.to_sym] || field_types[key.to_s]
            #logger.info "key: #{key} type: #{type}"
            if valid_types.include? type
              mapped[key] = fix_field_type(type, value, key)
              mapped["_#{key}"] = value.downcase if type == "name"
            else
              raise InvalidDictionary, "unexpected type #{type.inspect} " +
                "for field #{key}"
            end
          end
        end
        #logger.info "mappped: #{mapped.inspect}"
        mapped
      end

      def parse_nested(document, options)
        new_doc = {}
        nest_options = options[:nest]
        if nest_options
          #logger.info "nest: #{nest_options.to_yaml}"
          #logger.info "add to document: #{document.inspect[0..255]}"
          key = nest_options['key']
          new_doc[key] = {}

          id = document['id']
          new_doc['id'] = id unless id.nil?

          nest_options['contents'].each do |item_key|
            #logger.info "adding item #{item_key}"
            new_doc[key][item_key] = document[item_key]
          end
        end
        #logger.info "here it is: #{new_doc}"
        new_doc
      end

      def fix_field_type(type, value, key=nil)
        #logger.info "fix_field_type type:#{type.inspect} value: #{value.inspect} key: #{key.inspect}"
        return value if value.nil?

        new_value = case type
          when "float"
            value.to_f
          when "integer"
            value.to_i
          when "lowercase_name"
            value.to_s.downcase   # used for searching
          else # "string"
            value.to_s
        end
        new_value = value.to_f if key and key.to_s.include? "location"
        #logger.info "new_value #{new_value.inspect}"
        new_value
      end

      # currently we just support 'or' operations on two columns
      def calculate(field_name, row, dictionary)
        item = dictionary[field_name.to_s] || dictionary[field_name.to_sym]
        raise "calculate: field not found in dictionary #{field_name.inspect}" if item.nil?
        #logger.debug("row #{row.inspect}")
        #logger.debug("calculate item #{item.inspect}")
        expr = item['calculate'] || item[:calculate]
        raise ArgumentError, "expected to calculate #{field_name}" if expr.nil?
        cols = Expression.new(expr, field_name).variables #if expr.is_a? String
        cols = cols.map { |c| row[c.to_sym] }
        cols = cols.map { |value| value == 'NULL' ? nil : value }
        a, b = cols.map { |c| (fix_field_type(item['type'], c)) }
        #logger.debug("final: data #{cols.inspect} #{a.inspect} #{b.inspect} #{(a || b).inspect}")
        a || b
      end

      # row: a hash  (keys may be strings or symbols)
      # new_fields: hash current_name : new_name
      # returns a hash (which may be a subset of row) where keys are new_name
      #         with value of corresponding row[current_name]
      def map_field_names(row, new_fields, config, options={})
        mapped = {}
        row.each do |key, value|
          raise ArgumentError, "column header missing for: #{value}" if key.nil?
          new_key = new_fields[key.to_sym] || new_fields[key.to_s]
          #logger.info "key: #{key.inspect}, new_key:#{new_key.inspect}"
          if new_key
            value = value.to_f if new_key.include? "location"
            mapped[new_key] = value
          elsif options[:columns] == 'all'
            mapped[key] = value
          end
        end
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
