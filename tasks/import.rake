require 'data_magic'

desc "import files from /data directory"
task :import => :environment do
  # collect list of csv files, searching directories recursively
  files = Dir.glob("./data/**/*.csv").select { |entry| File.file? entry }
  puts "files found: #{files.length}"

  files.each do |filepath|
    puts filepath
    begin
      File.open(filepath) do |file|
        rows, fields = DataMagic.import_csv('data', file)
        puts "imported #{rows} rows"
      end
    rescue Exception => e
      puts "#{filepath} #{e.message}"
    end
  end

end
