require 'data_magic'

desc "import files from /data directory, to ignore invalid utf8 chars use rake import[force]"
task :import, [:encoding] => :environment do |t, args|
  # collect list of csv files, searching directories recursively
  files = Dir.glob("./data/**/*.csv").select { |entry| File.file? entry }
  puts "files found: #{files.length}"
  options = {}
  if args[:encoding] == "force"
    options[:force_utf8] = true
  end

  files.each do |filepath|
    puts filepath
    begin
      File.open(filepath) do |file|
        rows, fields = DataMagic.import_csv('data', file, options)
        puts "imported #{rows} rows"
      end
    rescue Exception => e
      puts "#{filepath} #{e.message}"
    end
  end

end
