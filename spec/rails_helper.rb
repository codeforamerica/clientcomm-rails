# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'
require 'webmock/rspec'
require 'capybara/rails'
require 'capybara/rspec'
require 'capybara/poltergeist'

Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

ActiveRecord::Migration.maintain_test_schema!

# For ApplicationJob testing
ActiveJob::Base.queue_adapter = :test

# Capybara settings
headless_capybara = true
Capybara.server = :puma
Capybara.default_max_wait_time = 5

if headless_capybara
  Capybara.javascript_driver = :poltergeist
else
  Capybara.register_driver :chrome do |app|
    Capybara::Selenium::Driver.new(app, :browser => :chrome)
  end
  Capybara.javascript_driver = :chrome
end

# change to ':accessible_poltergeist' for accessibility warnings
# NOTE: you'll need to include the capybara-accessible gem
# Capybara.javascript_driver = :poltergeist

WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |config|
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.infer_spec_type_from_file_location!
  config.include ActiveSupport::Testing::TimeHelpers
  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # custom helpers, including steps
  config.include AnalyticsHelper
  config.include ResponsiveHelper
  config.include TwilioHelper
  config.include FeatureHelper, type: :feature
  config.include RequestHelper, type: :request
  # FactoryGirl methods
  config.include FactoryGirl::Syntax::Methods
  # Devise setup
  config.include Warden::Test::Helpers
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::ControllerHelpers, type: :view
  # So we can use dom_id
  config.include ActionView::RecordIdentifier

  config.around :each, :type => :feature do |example|
    ActiveJob::Base.queue_adapter.perform_enqueued_jobs = true
    example.run
    ActiveJob::Base.queue_adapter.perform_enqueued_jobs = false
  end
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
