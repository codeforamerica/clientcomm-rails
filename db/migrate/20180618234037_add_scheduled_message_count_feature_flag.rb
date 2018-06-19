class AddScheduledMessageCountFeatureFlag < ActiveRecord::Migration[5.1]
  def up
    FeatureFlag.create!(
      flag: 'scheduled_message_flag',
      enabled: false
    )
  end
end
