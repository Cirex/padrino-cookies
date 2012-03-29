PADRINO_ENV = 'test'

require 'rspec'
require 'rack/test'
require 'padrino-cookies'

module TestHelpers
  def app
    @app ||= Sinatra.new(Padrino::Application) do
      register Padrino::Cookies
      disable :logging
    end
  end

  def route(*cookies, &block)
    result = nil
    set_cookie(cookies)
    app.get('cookies') { result = instance_eval(&block) }
    get 'cookies'
    result
  end
end

RSpec.configure do |configuration|
  configuration.include TestHelpers
  configuration.include Rack::Test::Methods
end

