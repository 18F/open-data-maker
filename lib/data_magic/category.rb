Category = Struct.new(:category_id) do
  def assemble
    category_entry = DataMagic.config.data['categories'][category_id]
    dictionary = DataMagic.config.dictionary
    field_details = {}
    category_entry['fields'].each do |field_name|
      field_details[field_name] = dictionary[field_name] || { "description"=>"" }
    end
    field_details = { "field_details" => field_details }
    assemble = category_entry.merge(field_details)
  end
end
