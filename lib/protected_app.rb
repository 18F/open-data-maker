
# Create a middleware to add HTTP basic auth to all but the whitelisted paths
# inspired by: https://gist.github.com/mildmojo/2967459
class ProtectedApp
  WHITELIST_REGEX = %r{^https:\/\/[\w\.-]*.18f.gov$}

  def initialize(app, realm=nil, &authenticator)
    ENV['DATA_AUTH'] ||= ""

    @app = app
    @authenticator = Rack::Auth::Basic.new( app, "Restricted Area") do |username, password|
      authorized_user, authorized_pass = ENV['DATA_AUTH'].split(',')
      username == authorized_user and password == authorized_pass
    end

  end

  def call(env)
    request = Rack::Request.new(env)
    authorized = false
    authorized = true if request.referer =~ WHITELIST_REGEX
    authorized = true if ENV['DATA_AUTH'].empty?
    if authorized
       @app.call(env)
    else
      @authenticator.call(env)
    end
  end
end
