require 'data_magic'

namespace :es do
  desc "delete index (_all for all)"
  task :delete, [:index_name] => :environment do |t, args|
    DataMagic.client.indices.delete(index: args[:index_name])
  end

  desc "list indices"
  task :list => :environment do |t, args|
    result = DataMagic.client.indices.get(index: '_all').keys
    puts result.join('\r')
  end
end
