# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
Rails.application.config.filter_parameters += %i[
  body
  password
]

Rails.application.config.filter_parameters << lambda do |param_name, value|
  value.gsub!(/.+/, '[FILTERED]') if %w[From To].include?(param_name) && value.respond_to?(:gsub!)
end
