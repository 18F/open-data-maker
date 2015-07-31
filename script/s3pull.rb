require_relative 's3config.rb'

@s3 = ::Aws::S3::Client.new

bucket = ENV['s3_bucket']
File.open("#{bucket}.yaml", 'w') do |file|
  response = @s3.get_object(bucket: bucket, key: 'data.yaml')
  file << response.body.read
end
