class AddLastTwilioUpdateToMessage < ActiveRecord::Migration[5.1]
  def change
    add_column :messages, :last_twilio_update, :string
  end
end
