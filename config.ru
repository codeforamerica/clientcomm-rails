# This file is used by Rack-based servers to start the application.

require_relative 'config/environment'
if Rails.env.development?
  require 'dotenv/load'
end

run Rails.application
