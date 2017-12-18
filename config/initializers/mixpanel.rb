mixpanel_token = ENV['MIXPANEL_TOKEN']
return if mixpanel_token.nil?

MIXPANEL_TRACKER = Mixpanel::Tracker.new(mixpanel_token)
# silence local SSL errors
if Rails.env.development?
  Mixpanel.config_http do |http|
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end
end
