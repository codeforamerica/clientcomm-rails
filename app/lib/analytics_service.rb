require 'device_detector'
require 'mixpanel-ruby'

class AnalyticsService
  def self.track(distinct_id:, label:, user_agent: nil, data: {})
    if MIXPANEL_TRACKER
      if user_agent
        client = DeviceDetector.new(user_agent)
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

      data[:locale] = I18n.locale
      MIXPANEL_TRACKER.track(distinct_id, label, data)
    end
  rescue StandardError => err
    Rails.logger.error "Error tracking analytics event #{err}"
  end

  def self.alias(internal_id, visitor_id)
    MIXPANEL_TRACKER.alias(internal_id, visitor_id)
  end
end
