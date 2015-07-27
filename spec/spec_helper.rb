ENV['DATA_PATH']  = nil
ENV['RACK_ENV'] ||= 'test'
RACK_ENV          = ENV['RACK_ENV'] unless defined?(RACK_ENV)

#require File.expand_path(File.dirname(__FILE__) + "/../config/boot")
require_relative '../config/env.rb'
Dir[File.expand_path(File.dirname(__FILE__) + "/../app/helpers/**/*.rb")].each(&method(:require))

RSpec.configure do |config|
  config.include Rack::Test::Methods

  config.before(:type => :feature) do
    # load the Padrino web app defined in app/app.rb
    require_relative '../config/boot'
  end
  config.before do
    ENV['DATA_PATH'] = nil
  end
end

# You can use this method to custom specify a Rack app
# you want rack-test to invoke:
#
#   app OpenDataMaker::App
#   app OpenDataMaker::App.tap { |a| }
#   app(OpenDataMaker::App) do
#     set :foo, :bar
#   end
#
def app(app = nil, &blk)
  @app ||= block_given? ? app.instance_eval(&blk) : app
  @app ||= Padrino.application
end
