Category = Struct.new(:name, :description, :fields) do
  class << self
  	def from_yml
      DataMagic.config.data['categories'].map do |key, value|
        new(value['title'], value['description'], ['field1', 'field2'])
      end
  	end
  end
end