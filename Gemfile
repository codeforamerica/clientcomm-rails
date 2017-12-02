source 'https://rubygems.org'
ruby File.read(File.join(File.dirname(__FILE__), '.ruby-version')).strip

gem 'activeadmin'
gem 'delayed_job_active_record'
gem 'delayed_job_web'
gem 'device_detector'
gem 'devise'
gem 'pg', '~> 0.18'
gem 'puma', '~> 3.0'
gem 'rails', '~> 5.1.0'
gem 'timeliness'
gem 'twilio-ruby'
gem 'uglifier', '>= 1.3.0'
gem 'validates_timeliness'

gem 'autosize'
gem 'bootstrap-sass'
gem 'bourbon', '~> 4.2.0'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'neat', '~> 1.8.0'
gem 'premailer-rails'
gem 'sass-rails', '~> 5.0'

gem 'intercom-rails'
gem 'mixpanel-ruby'
gem 'sentry-raven'
gem 'skylight'

gem 'aws-sdk', '~> 2'
gem 'paperclip'

group :test do
  gem 'capybara-screenshot'
  gem 'codeclimate-test-reporter', '1.0.8', require: false
  gem 'launchy', require: false
  gem 'shoulda-matchers'
  gem 'simplecov', require: false
end

group :development, :test do
  gem 'action-cable-testing'
  gem 'addressable'
  gem 'awesome_print'
  gem 'byebug', platform: :mri
  gem 'capybara'
  gem 'database_cleaner'
  gem 'dotenv-rails'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'faraday'
  gem 'jasmine-rails'
  gem 'overcommit'
  gem 'poltergeist'
  gem 'pry-byebug'
  gem 'rspec-rails'
  gem 'rspec_junit_formatter'
  gem 'rubocop'
  gem 'selenium-webdriver'
  gem 'webmock'
end

group :development do
  gem 'listen'
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'spring-watcher-listen'
  gem 'web-console'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
