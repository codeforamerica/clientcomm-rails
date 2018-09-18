require 'fuzzystringmatch'

class FuzzyMatcher
  def self.get_distance(string_a:, string_b:)
    FuzzyStringMatch::JaroWinkler.create(:native).getDistance(string_a, string_b)
  end
end
