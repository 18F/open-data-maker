require 'data_magic'
require 'json'
require 'yaml'

namespace :cf do
    desc "Only run on the first application instance"
    task :on_first_instance do
      puts "--"*40
      puts "    on_first_instance #{ENV['VCAP_APPLICATION']}"
      puts "--"*40
       begin
         app_data = JSON.parse(ENV['VCAP_APPLICATION'])
         puts "app_data: #{app_data.inspect}"
         instance_index = app_data["instance_index"]
       rescue e => Exception
         puts "on_first_instance exception: #{e.class} #{e.message}"
       end
       puts "instance_index: #{instance_index}"
    exit(0) unless instance_index == 0
    end

    desc "Update the Elasticsearch Index if needed"
    task :index do
      puts "--"*40
      puts "     index "
      puts "--"*40
      begin
        config = YAML.load_file("./data/data.yaml")
        puts "config #{config}"
        prior_version = ENV['DATA_VERSION']
        puts "DATA_VERSION: #{ENV['DATA_VERSION'].inspect}"
        DataMagic.delete_all
        DataMagic.import_all('./data')
        ENV['DATA_VERSION'] = config.version
        puts "DATA_VERSION:#{ENV['DATA_VERSION'].inspect} config.version:#{config.version}"
      rescue e => Exception
        puts "index exception: #{e.class} #{e.message}"
      end
      puts "======= done ======="

    end

end
