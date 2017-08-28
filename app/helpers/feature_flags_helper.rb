module FeatureFlagsHelper
  class FeatureFlags
    def search_and_sort
      ENV['SEARCH_AND_SORT'] == 'true'
    end

    def mass_messages
      ENV['MASS_MESSAGES'] == 'true'
    end
  end
end
