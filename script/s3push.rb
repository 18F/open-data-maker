require 'dotenv'

branch = `echo $(git symbolic-ref --short HEAD)`.chomp
if branch == "master"
  APP_ENV = "production"
else
  puts "not on master branch lets use staging"
  APP_ENV = "staging"
end


Dotenv.load(
  File.expand_path("../../.#{APP_ENV}.env", __FILE__),
  File.expand_path("../../.env",  __FILE__))

require 'aws-sdk'
puts "app env: #{APP_ENV}"
puts "bucket name: #{ENV['s3_bucket']}"


s3cred = {'access_key'=>  ENV['s3_access_key'], 'secret_key' => ENV['s3_secret_key']}

::Aws.config[:credentials] = ::Aws::Credentials.new(s3cred['access_key'], s3cred['secret_key'])
::Aws.config[:region] = 'us-east-1'
@s3 = ::Aws::S3::Client.new

datayamlpath = File.expand_path("../../real-data/data.yaml",  __FILE__)

File.open(datayamlpath, 'r') do |file|
  @s3.put_object(bucket: ENV['s3_bucket'], key: 'data.yaml', body: file)
end
