# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

gem 'gem-release'
gem 'jwt'
gem 'rake'

# Pin to newer versions for security
gem 'omniauth', '~> 2.0'
gem 'rack', '~> 3.0'

group :development do
  gem 'dotenv'
  gem 'pry'
  gem 'rubocop', require: false
  gem 'shotgun'
  gem 'sinatra'
  gem 'thin'
end

group :test do
  gem 'codecov', require: false
  gem 'guard-rspec', require: false
  gem 'listen', '~> 3.5'
  gem 'multi_json'
  gem 'omniauth-rails_csrf_protection' # For OmniAuth 2.x testing
  gem 'rack-test', '~> 2.0'
  gem 'rspec', '~> 3.12'
  gem 'simplecov'
  gem 'webmock'
end
