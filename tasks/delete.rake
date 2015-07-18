require 'data_magic'

desc "delete index (_all for all)"
task :delete, [:index_name] => :environment do |t, args|
  DataMagic::Index.delete(args[:index_name])
end
