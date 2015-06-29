class NestedHash < Hash

  def add(hash)
    hash.each do |full_name, value|
      parts = full_name.to_s.split('.')
      last = parts.length - 1
      add_to = self
      parts.each_with_index do |name, index|
        if index == last
          add_to[name] = value
        else
          add_to[name] ||= {}
          add_to = add_to[name]
        end
      end
    end
    self
  end
end
