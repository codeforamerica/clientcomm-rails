class SetSendAtOnMessages < ActiveRecord::Migration[5.0]
  def change
    Message.all.each do |message|
      if message.send_at.nil?
        message.update(send_at: message.created_at)
      end
    end

    change_column :messages, :send_at, :datetime, null: false
  end
end
