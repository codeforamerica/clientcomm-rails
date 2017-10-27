source 'https://rubygems.org'
ruby File.read(File.join(File.dirname(__FILE__), '.ruby-version')).strip

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.1.0'
# Use postgresql as the database for Active Record
gem 'pg', '~> 0.18'
# Use Puma as the app server
gem 'puma', '~> 3.0'
# Use SCSS for stylesheets
gem 'bootstrap-sass'
gem 'sass-rails', '~> 5.0'
gem 'bourbon', '~> 4.2.0'
gem 'neat', '~> 1.8.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use Delayed Job for background tasks
gem 'delayed_job_active_record'
gem 'delayed_job_web'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby
gem 'mixpanel-ruby'
gem 'device_detector'
gem 'twilio-ruby'
gem 'intercom-rails'
gem 'devise'

# Dependency for Paperclip. Pinned to 2 due to changes in gem architecture on versions 3+.
gem 'aws-sdk', '~> 2'

gem 'autosize'

gem 'timeliness'
gem 'validates_timeliness'

# Use jquery as the JavaScript library
gem 'jquery-rails'
gem 'jquery-ui-rails'

gem 'activeadmin'

# Metrics and performance tracking
gem 'skylight'
gem 'sentry-raven'

# Attached media files
gem 'paperclip'

group :test do
  gem 'launchy', require: false
  gem 'capybara-screenshot'
  gem 'simplecov', require: false
  gem 'codeclimate-test-reporter', require: false
  gem 'shoulda-matchers', git: 'https://github.com/thoughtbot/shoulda-matchers.git', branch: 'rails-5'
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'addressable'
  gem 'byebug', platform: :mri
  gem 'capybara'
  gem 'database_cleaner'
  gem 'dotenv-rails'
  gem 'factory_bot_rails'
  gem 'faraday'
  gem 'poltergeist'
  gem 'pry-rails'
  gem 'rspec_junit_formatter'
  gem 'rspec-rails'
  gem 'selenium-webdriver'
  gem 'webmock'
  gem 'jasmine'
  gem 'awesome_print'
  gem 'faker'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console'
  gem 'listen', '~> 3.0.5'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'spring-commands-rspec'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
