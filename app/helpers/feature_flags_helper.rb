module FeatureFlagsHelper
  class FeatureFlags
    def mass_messages
      ENV['MASS_MESSAGES'] == 'true'
    end
  end
end
