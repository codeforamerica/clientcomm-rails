require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_view/railtie'
require 'action_cable/engine'
require 'sprockets/railtie'
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Clientcomm
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # validate Twilio POSTs
    # see https://www.twilio.com/blog/2014/09/securing-your-ruby-webhooks-with-rack-middleware.html
    # see https://github.com/twilio/twilio-ruby/blob/master/lib/rack/twilio_webhook_authentication.rb
    config.middleware.use Rack::TwilioWebhookAuthentication, ENV['TWILIO_AUTH_TOKEN'], '/incoming'

    # Use delayed job for the job queue
    config.active_job.queue_adapter = :delayed_job

    # Configure external DSN
    if ENV['SENTRY_ENDPOINT']
      Raven.configure do |config|
        config.dsn = ENV['SENTRY_ENDPOINT']
        config.tags = { server_name: ENV['DEPLOYMENT'] }
      end
    end

    # Set the time zone from ENV, or default to UTC
    config.time_zone = ENV['TIME_ZONE'] || 'UTC'

    Dir.glob("#{Rails.root}/app/assets/images/**/").each do |path|
      config.assets.paths << path
    end
  end
end
