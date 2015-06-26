require 'rack/mock.rb'

describe "authorization" do
  let(:app) { ->(env) { [200, env, "app"] } }
  let :middleware do
    ProtectedApp.new(app)
  end

  def env_for url, opts={}
    Rack::MockRequest.env_for(url, opts)
  end

  it "allows requests from https://*.18f.gov" do
    ENV['DATA_AUTH'] = nil
    code, env = middleware.call env_for('http://whatever.gov', 'HTTP_REFERER' => 'https://whatever.18f.gov')
    expect(code).to eq(200)
  end
  it "required for request from https://anywhere.com" do
    ENV['DATA_AUTH'] = "name,something"
    code, env = middleware.call env_for('http://whatever.gov', 'HTTP_REFERER' => 'https://anywhere.com')
    expect(code).to eq(401)
  end
  it "required for request from https://anywhere.com" do
    ENV['DATA_AUTH'] = "name,something"
    code, env = middleware.call env_for('http://whatever.gov', 'HTTP_REFERER' => 'https://anywhere.com?https://whatever.18f.gov')
    expect(code).to eq(401)
  end
end
