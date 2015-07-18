require 'data_magic'

namespace :es do
  desc "delete elasticsearch index (_all for all)"
  task :delete, [:index_name] => :environment do |t, args|
    DataMagic.client.indices.delete(index: args[:index_name])
  end

  desc "list elasticsearch indices"
  task :list => :environment do |t, args|
    result = DataMagic.client.indices.get(index: '_all').keys
    puts result.join("\n")
  end
end
