require 'csv'

module OpenDataMaker

  class IndexApp < Padrino::Application
    register SassInitializer
    register Padrino::Helpers

    enable :sessions

    get '/' do
      DataMagic.config.scoped_index_name
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
