require 'data_magic'

desc "delete index (_all for all)"
task :delete, [:index_name] => :environment do |t, args|
  DataMagic.delete_index(args[:index_name])
end
