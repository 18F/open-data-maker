require 'forwardable'

require_relative 'config'
require_relative 'builder_data'
require_relative 'event_logger'
require_relative 'document'
require_relative 'document_builder'
require_relative 'importer'
require_relative 'output'
require_relative 'repository'
require_relative 'super_client'

require 'action_view'  # for distance_of_time_in_words (logging time)
include ActionView::Helpers::DateHelper  # for distance_of_time_in_words (logging time)

module DataMagic
  # data could be a String or an io stream
  def self.import_csv(data, options={})
    importer = Importer.new(data, options)
    importer.setup

    begin
      CSV.parse(
        importer.data,
        headers: true,
        header_converters: lambda { |str| str.strip.to_sym }
      ) do |row|
        row_importer = RowImporter.new(row, importer)
        row_importer.process
        break if importer.at_limit?
      end
    rescue InvalidData => e
      Config.logger.error e.message
      raise InvalidData, "invalid file format" if importer.empty?
    end

    importer.finish!

    return [importer.row_count, importer.headers]
  end

  def self.import_with_dictionary(options = {})
    start_time = Time.now
    Config.logger.debug "--- import_with_dictionary, starting at #{start_time}"

    #logger.debug("field_mapping: #{field_mapping.inspect}")
    options[:mapping] = config.field_mapping
    options = options.merge(config.options)

    es_index_name = self.config.load_datayaml(options[:data_path])
    unless config.index_exists?(es_index_name)
      logger.info "creating #{es_index_name}"   # TO DO: fix #14
      create_index es_index_name, config.field_types
    end

    logger.info "files: #{self.config.files}"
    config.files.each_with_index do |filepath, index|
      fname = filepath.split('/').last
      logger.debug "indexing #{fname} #{index} file config:#{config.additional_data_for_file(index).inspect}"
      options[:add_data] = config.additional_data_for_file(index)
      options[:only] = config.info_for_file(index, :only)
      options[:nest] = config.info_for_file(index, :nest)
      begin
        logger.debug "*"*40
        logger.debug "*    #{filepath}"
        logger.debug "*"*40
        data = config.read_path(filepath)
        rows, _ = DataMagic.import_csv(data, options)
        logger.debug "imported #{rows} rows"
      rescue DataMagic::InvalidData => e
       Config.logger.debug "Error: skipping #{filepath}, #{e.message}"
      end
    end
    end_time = Time.now
    logger.debug "indexing complete: #{distance_of_time_in_words(end_time, start_time)}"
    logger.debug "duration: #{end_time - start_time}"
  end # import_with_dictionary

private
  def self.valid_types
    %w[integer float string literal name autocomplete boolean]
  end

end # module DataMagic
