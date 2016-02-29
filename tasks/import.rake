require 'data_magic'
require 'ruby-prof'

desc "import files from DATA_PATH, rake import[profile=true] for profile output"
task :import, [:profile] => :environment do |t, args|
  options = {}
  start_time = Time.now
  RubyProf.start if args[:profile]

  DataMagic.import_with_dictionary(options)

  if args[:profile]
      result = RubyProf.stop
    end_time = Time.now
    puts "indexing complete: #{distance_of_time_in_words(end_time, start_time)}"
    puts "duration: #{end_time - start_time}"

    printer = RubyProf::MultiPrinter.new(result);
    printer.print(path: ".", profile: "profile", min_percent: 2)
  end
end
