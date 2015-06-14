begin
  require 'rspec/core/rake_task'

  spec_tasks = Dir['spec/*/'].each_with_object([]) do |d, result|
    result << File.basename(d) unless Dir["#{d}*"].empty?
  end

  spec_tasks.each do |folder|
    desc "Run the spec suite in #{folder}"
    RSpec::Core::RakeTask.new("spec:#{folder}") do |t|
      t.pattern = "./spec/#{folder}/**/*_spec.rb"
      t.rspec_opts = "--color"
    end
  end

  desc "Run complete application spec suite"
  task 'spec' => spec_tasks.map { |f| "spec:#{f}" }
rescue LoadError
  puts "RSpec is not part of this bundle, skip specs."
end
