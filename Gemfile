source 'https://rubygems.org'

ruby '2.2.3'

gem 'active_model_serializers', '0.8.3'
gem 'administrate', '~> 0.0.8'
gem 'analytics-ruby', '~> 2.0.0', require: 'segment/analytics'
gem 'angular_rails_csrf'
gem 'angularjs-rails'
gem 'attr_extras'
gem 'bourbon'
gem 'coffee-rails'
gem 'coffeelint'
gem 'email_validator'
gem 'faraday'
gem 'font-awesome-rails'
gem 'haml-rails'
gem 'haml_lint'
gem 'high_voltage'
gem 'jquery-rails', '~> 3.1.3'
gem 'jshintrb'
gem 'neat'

gem 'octokit'
gem 'gitlab'

# fixed version until issue #81 is solved
# https://github.com/intridea/omniauth-oauth2/issues/81
gem 'omniauth-oauth2', '1.3.1'

gem 'omniauth-gitlab'
gem 'paranoia', '~> 2.0'
gem 'pg'
gem 'puma'
gem 'rails', '4.2.4'
gem 'resque', '~> 1.25.0'
gem 'resque-scheduler'
gem 'rubocop', '0.34.2'
gem 'sass-rails'
gem 'split', require: 'split/dashboard'
gem 'stripe'
gem 'uglifier', '>= 2.7.2'
gem 'rest-client', '>= 1.8.0'
gem 'dotenv-rails'
gem 'foreman'

group :staging, :production do
  gem 'rack-timeout'
  gem 'rails_12factor'
  gem 'sentry-raven', '>= 0.12.2'
end

group :development, :test do
  gem 'pry-byebug'
  gem 'jasmine-rails'
  gem 'poltergeist'
  gem 'rspec-rails', '>= 3.2'
  gem 'bundler-audit'
end

group :test do
  gem 'capybara', '~> 2.4.0'
  gem 'capybara-webkit', '~> 1.5.1'
  gem 'database_cleaner'
  gem 'factory_girl_rails'
  gem 'launchy'
  gem 'shoulda-matchers'
  gem 'webmock'
end
