class Example < Hashie::Mash
  include Hashie::Extensions::Coercion
  include Hashie::Extensions::MergeInitializer
  coerce_key :name, String
  coerce_key :description, String
  coerce_key :params, String
  coerce_key :endpoint, String
  coerce_key :link, String
  def initialize(hash = {})
   super
   # we want to use this in a liquid template
   # so all attributes needs to be plain data, not code
   self[:link] = "/#{endpoint}?#{params}" if self[:link].nil?
 end

end
