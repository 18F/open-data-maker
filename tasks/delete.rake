require 'data_magic'

namespace :delete do

  desc "delete all elasticsearch indices"
  task :all => :environment do
    DataMagic.delete_all
  end

end
