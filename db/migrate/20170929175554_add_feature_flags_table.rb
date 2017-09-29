class AddFeatureFlagsTable < ActiveRecord::Migration[5.1]
  def up
    create_table :feature_flags do |t|
      t.string :flag
      t.boolean :enabled, null: false
    end

    FeatureFlag.create!(
      flag: "mass_messages",
      enabled: (ENV["MASS_MESSAGES"] == 'true')
    )

    FeatureFlag.create!(
      flag: "allow_signups",
      enabled: (ENV["ALLOW_SIGNUPS"] == 'true')
    )

    FeatureFlag.create!(
      flag: "templates",
      enabled: false
    )
  end

  def down
    drop_table :feature_flags
  end
end
