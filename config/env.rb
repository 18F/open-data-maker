# define core environment that we need in tests and for the app

# Defines our constants
ENV['RACK_ENV'] ||= 'development'
RACK_ENV          = ENV['RACK_ENV'] unless defined?(RACK_ENV)
PADRINO_ROOT      = File.expand_path('../..', __FILE__) unless defined?(PADRINO_ROOT)

# Load our dependencies
require 'rubygems' unless defined?(Gem)
require 'bundler/setup'
require 'newrelic_rpm'
Bundler.require(:default, RACK_ENV)

# do this early so we can log during startup
require './lib/data_magic/config.rb'
DataMagic::Config.logger=Logger.new(STDOUT) if ENV['VCAP_APPLICATION']    # Cloud Foundry
