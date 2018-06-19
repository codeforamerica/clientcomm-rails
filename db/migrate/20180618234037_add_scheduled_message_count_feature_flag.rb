class AddScheduledMessageCountFeatureFlag < ActiveRecord::Migration[5.1]
  def up
    FeatureFlag.create!(
      flag: 'scheduled_message_count',
      enabled: false
    )
  end
end
