require 'csv'

module OpenDataMaker
  class App < Padrino::Application
    register SassInitializer
    register Padrino::Helpers

    # This app is stateless and session cookies prevent caching of API responses
    disable :sessions

    # This app has no sensitive bits and csrf protection requires sessions
    disable :protect_from_csrf

    if ENV['DATA_AUTH'] and not ENV['DATA_AUTH'].empty?
      auth = ENV['DATA_AUTH']
      authorized_user, authorized_pass = auth.split(',')
      use Rack::Auth::Basic, "Restricted Area" do |username, password|
        username == authorized_user and password == authorized_pass
      end
    end

    ## app setup
    if ENV['RACK_ENV'] == 'test'
      DataMagic.init(load_now: true)
    else
      DataMagic.init(load_now: false)   # don't index data
    end

  end

end
