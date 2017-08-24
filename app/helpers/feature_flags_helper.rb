module FeatureFlagsHelper
  class FeatureFlags
    def search_and_sort
      ENV['SEARCH_AND_SORT'] == 'true'
    end
  end
end
