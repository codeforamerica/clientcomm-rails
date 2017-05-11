require 'device_detector'
require 'mixpanel-ruby'
require 'singleton'

class AnalyticsService
  include Singleton

  def initialize
    mixpanel_key = Rails.application.secrets.mixpanel_key
    return if mixpanel_key.nil?

    @tracker = Mixpanel::Tracker.new(mixpanel_key)
    # silence local SSL errors
    if Rails.env.development?
      Mixpanel.config_http do |http|
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
    end
  end

  def track(distinct_id: nil, label:, request: nil, session: nil, data: {})
    distinct_id ||= session[:visitor_id]

    unless @tracker.nil?
      unless request.nil?
        client = DeviceDetector.new(request.env['HTTP_USER_AGENT'])
        data[:client_bot_name] = client.bot_name
        data[:client_full_version] = client.full_version
        data[:client_major_version] = client.full_version.partition('.').first unless client.full_version.nil?
        data[:client_is_bot] = client.bot?
        data[:client_name] = client.name
        data[:client_device_brand] = client.device_brand
        data[:client_device_name] = client.device_name
        data[:client_device_type] = client.device_type
        data[:client_os_full_version] = client.os_full_version
        data[:client_os_major_version] = client.os_full_version.partition('.').first unless client.os_full_version.nil?
        data[:client_os_name] = client.os_name
      end

      unless session.nil?
        data[:source] = session[:source]
        data[:visitor_id] = session[:visitor_id]
      end

      data[:locale] = I18n.locale

      @tracker.track(distinct_id, label, data)
    end
  rescue => err
    Rails.logger.error "Error tracking analytics event #{err}"
  end
end
