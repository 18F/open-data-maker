module CSVFieldHelpers
  def recursive_keys(row, prefix = '', path = [])
    human_names = []
    paths = []
    row.keys.each do |key|
      if row[key].is_a?(Hash)
        new_human_names, new_paths = recursive_keys(row[key], key + '.', path + [key])
        human_names += new_human_names
        paths += new_paths
      else
        human_names << prefix + key
        paths << path + [key]
      end
    end

    [human_names, paths]
  end

  def recursive_fields(row, path_list)
    path_list.map do |paths|
      current_value = row
      paths.each do |path_entry|
        current_value = current_value[path_entry]
      end
      current_value
    end
  end
end