# configure S3 with local credentials based on environment
# usage (from ruby script or irb):
#    require 's3config.rb'
#    @s3 = ::Aws::S3::Client.new

require 'dotenv'
require 'json'

branch = `echo $(git symbolic-ref --short HEAD)`.chomp

if ENV['APP_ENV']
  APP_ENV = ENV['APP_ENV']
  puts "using APP_ENV from environment #{APP_ENV}"
else
  case branch
  when "master"
    APP_ENV = "production"
  when "staging"
    APP_ENV = "staging"
  else
    puts "not on master or staging branch lets use dev"
    APP_ENV = "dev"  # FIXME: shouldn't the APP_ENV be testing?
  end
end

cf_credentials = `cf target -o ed -s #{APP_ENV} && echo "$(cf env ccapi)" | tail -n +5 |  sed -n -e :a -e '1,10!{P;N;D;};N;ba'`
cf_json_str = cf_credentials.gsub("\n", '').gsub(/^[^{]+{/, '{').gsub(/{\s+"VCAP_APPLICATION".+$/, '')

cf_json = JSON.parse(cf_json_str)
cf_data_files = cf_json['VCAP_SERVICES']['s3'].detect {|j| j['name'] == 'data-files'}

fail "Unable to find data-files configuration" if cf_data_files.nil?

ENV['CF_CREDENTIALS'] = cf_json_str
ENV['AWS_ACCESS_KEY_ID'] = cf_data_files['credentials']['access_key_id']
ENV['AWS_SECRET_ACCESS_KEY'] = cf_data_files['credentials']['secret_access_key']
ENV['BUCKET_NAME'] = cf_data_files['credentials']['bucket']

require 'aws-sdk'
puts "app env: #{APP_ENV}"
puts "bucket name: #{ENV['BUCKET_NAME']}"

s3cred = {'access_key'=>  ENV['AWS_ACCESS_KEY_ID'], 'secret_key' => ENV['AWS_SECRET_ACCESS_KEY']}

::Aws.config[:credentials] = ::Aws::Credentials.new(s3cred['access_key'], s3cred['secret_key'])
::Aws.config[:region] = 'us-east-1'
