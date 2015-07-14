require 'data_magic'

desc "import files from /data directory, to ignore invalid utf8 chars use rake import[force]"
task :import, [:encoding] => :environment do |t, args|
  options = {}
  if args[:encoding] == "force"
    options[:force_utf8] = true
  end
  DataMagic.import_all(options)

end
