module FeatureFlagsHelper
  class FeatureFlags
    def scheduled_messages
      ENV['SCHEDULED_MESSAGES'] == 'true'
    end
  end
end
