# configure S3 with local credentials based on environment
# usage (from ruby script or irb):
#    require 's3config.rb'
#    @s3 = ::Aws::S3::Client.new

require 'dotenv'

branch = `echo $(git symbolic-ref --short HEAD)`.chomp
case branch
  when "master"
    APP_ENV = "production"
  when "staging"
    APP_ENV = "staging"
  else
    puts "not on master or staging branch lets use dev"
    APP_ENV = "dev"
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
