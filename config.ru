# This file is used by Rack-based servers to start the application.

require_relative 'config/environment'
require 'dotenv/load'

run Rails.application
