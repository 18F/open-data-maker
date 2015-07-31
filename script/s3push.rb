require_relative 's3config.rb'

@s3 = ::Aws::S3::Client.new

datayamlpath = File.expand_path("../../real-data/data.yaml",  __FILE__)

File.open(datayamlpath, 'r') do |file|
  @s3.put_object(bucket: ENV['s3_bucket'], key: 'data.yaml', body: file)
end
