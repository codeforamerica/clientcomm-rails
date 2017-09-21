class MakeLastContactedAtNullable < ActiveRecord::Migration[5.1]
  def up
    change_column :clients, :last_contacted_at, :datetime, null: true, default: nil

    Client.reset_column_information

    Client.all.each do |client|
      if client.messages.empty?
        client.update!(last_contacted_at: nil)
      end
    end
  end

  def down
    change_column :clients, :last_contacted_at, :datetime, null: false, default: -> { 'NOW()' }

    Client.reset_column_information

    Client.all.each do |client|
      last_message = client.messages.reverse.find { |message| message.send_at < Time.now }
      if last_message
        client.last_contacted_at = last_message.send_at
      else
        client.last_contacted_at = client.updated_at
      end

      client.save!
    end
  end
end
