require 'data_magic'

desc "import files from /data directory, to ignore invalid utf8 chars use rake import[force]"
task :import, [:encoding] => :environment do |t, args|
  options = {}
  if args[:encoding] == "force"
    options[:force_utf8] = true
  end
  dir_path = ENV['DATA_PATH']
  dir_path ||= DataMagic::DEFAULT_PATH
  DataMagic.import_all(dir_path, options)

end
