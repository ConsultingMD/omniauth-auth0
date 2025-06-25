# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path(__dir__)
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'simplecov'
SimpleCov.start

if ENV['CI'] == 'true'
  require 'codecov'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

require 'rspec'
require 'rack/test'
require 'webmock/rspec'
require 'omniauth'
require 'omniauth-auth0'
require 'sinatra'
require 'multi_json'

WebMock.disable_net_connect!

# Configure OmniAuth for testing
OmniAuth.config.test_mode = true
OmniAuth.config.allowed_request_methods = %i[get post]

# Set request validation phase to a proc that always returns true
OmniAuth.config.request_validation_phase = proc { |_env| true }

RSpec.configure do |config|
  config.include WebMock::API
  config.include Rack::Test::Methods
  config.extend OmniAuth::Test::StrategyMacros, type: :strategy

  def app
    @app || make_application
  end

  def make_application(options = {})
    client_id = 'CLIENT_ID'
    secret = "CLIENT_SECRET_#{'a' * 50}" # At least 64 chars for JWT HS256
    domain = 'samples.auth0.com'
    key_host = 'custom-keys.business.com'
    client_id = options.delete(:client_id) if options.key?(:client_id)
    secret = options.delete(:client_secret) if options.key?(:client_secret)
    domain = options.delete(:domain) if options.key?(:domain)

    Sinatra.new do
      configure do
        enable :sessions
        set :show_exceptions, false
        set :session_secret, "TEST_SESSION_SECRET_#{'a' * 50}" # At least 64 chars
      end

      # Middleware to set proper environment for OmniAuth 2.x tests
      use(Class.new do
        def initialize(app)
          @app = app
        end

        def call(env)
          # Set required environment variables for OmniAuth 2.x
          env['HTTP_HOST'] ||= 'test.host'
          env['HTTP_ORIGIN'] ||= 'http://test.host'
          env['SERVER_NAME'] ||= 'test.host'
          env['rack.url_scheme'] ||= 'http'

          # Add CSRF token for OmniAuth 2.x if this is an auth request
          if env['PATH_INFO'] =~ %r{^/auth/}
            env['rack.session'] ||= {}
            env['rack.session']['csrf'] = 'test_token'
            env['HTTP_X_CSRF_TOKEN'] = 'test_token'
          end

          @app.call(env)
        end
      end)

      use Rack::Session::Cookie, {
        key: 'rack.session',
        path: '/',
        secret: "TEST_SESSION_SECRET_#{'a' * 50}"
      }

      use TestOmniAuthBuilder do
        provider :auth0, client_id, secret, domain, key_host, options
      end

      get '/auth/auth0/callback' do
        MultiJson.encode(env['omniauth.auth'])
      end
    end
  end
end

OmniAuth.config.logger = Logger.new('/dev/null')
