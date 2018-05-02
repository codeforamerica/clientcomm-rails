class SetSendAtOnMessages < ActiveRecord::Migration[5.0]
  def change
    Message.all.each do |message|
      message.update(send_at: message.created_at) if message.send_at.nil?
    end

    change_column :messages, :send_at, :datetime, null: false
  end
end
