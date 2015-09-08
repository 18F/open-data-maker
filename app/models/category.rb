#Category = Struct.new(:name, :description, :fields) do
Category = Struct.new(:category_id) do
  def assemble  # abandoned this method for now
    category_entry = DataMagic.config.data['categories'][category_id]
    dictionary = DataMagic.config.data['dictionary']
    category_fields = {}
    category_entry['fields'].each do |field_name|
      category_fields[field_name] = dictionary[field_name] || { "description"=>"" }
    end
    category_fields = category_fields.to_a
    category_fields = { "fields" => category_fields }
    assemble = category_entry.merge(category_fields)
  end

  def category_entry
    category_entry = DataMagic.config.data['categories'][category_id]
  end

  def field_details
    dictionary = DataMagic.config.data['dictionary']
    field_details = {}
    category_entry['fields'].each do |field_name|
      field_details[field_name] = dictionary[field_name] || { "description"=>"" }
    end
    field_details
  end
end
