class AddCourtDatesFeatureFlag < ActiveRecord::Migration[5.1]
  def up
    FeatureFlag.create!(
      flag: 'court_dates',
      enabled: false
    )
  end
end
