require 'csv'

module OpenDataMaker

  class IndexApp < Padrino::Application
    register SassInitializer
    register Padrino::Helpers

    enable :sessions

    if ENV['INDEX_AUTH'] and not ENV['INDEX_AUTH'].empty?
      auth = ENV['INDEX_AUTH']
      authorized_user, authorized_pass = auth.split(',')
      use Rack::Auth::Basic, "Restricted Area" do |username, password|
        username == authorized_user and password == authorized_pass
      end
    end

    get '/init' do
      DataMagic.init(load_now: true)
      "ok"
    end

    get '/reindex' do
      DataMagic.reindex
      "reindexing..."
    end
  end

end
