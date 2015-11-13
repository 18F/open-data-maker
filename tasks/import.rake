require 'data_magic'

desc "import files from /data directory, to ignore invalid utf8 chars use rake import[force]"
task :import, [:encoding] => :environment do |_t, args|
  options = {}
  options[:force_utf8] = true if args[:encoding] == "force"
  DataMagic.import_with_dictionary(options)
end
