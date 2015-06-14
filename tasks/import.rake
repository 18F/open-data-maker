require 'data_magic'

task :import => :environment do
  puts "--------------- import files from /data directory ---"
  # collect list of files, searching directories recursively
  files = Dir.glob("./data/**/*").select { |entry| File.file? entry }
  puts "files found: #{files.length}"

  files.each do |filepath|
    puts filepath
    begin
      File.open(filepath) do |file|
        rows, fields = DataMagic.import_csv(file)
        puts "imported #{rows} rows"
      end
    rescue Exception => e
      puts "#{filepath} #{e.message}"
    end
  end

end
