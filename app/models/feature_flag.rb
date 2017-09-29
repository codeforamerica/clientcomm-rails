class FeatureFlag < ApplicationRecord
  validates :flag, presence: true, uniqueness: true
  validates_inclusion_of :enabled, in: [true, false]

  def self.enabled?(flag)
    feature = self.find_by_flag(flag)
    if feature
      feature.enabled
    else
      false
    end
  end
end
