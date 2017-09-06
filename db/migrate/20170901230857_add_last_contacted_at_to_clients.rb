class AddLastContactedAtToClients < ActiveRecord::Migration[5.0]
  def up
    add_column :clients, :last_contacted_at, :datetime, null: false, default: -> { 'NOW()' }
    add_column :clients, :has_unread_messages, :boolean, null: false, default: false

    Client.reset_column_information

    Client.all.each do |client|
      last_message = client.messages.reverse.find { |message| message.send_at < Time.now }
      if last_message
        client.last_contacted_at = last_message.send_at
      else
        client.last_contacted_at = client.updated_at
      end

      client.has_unread_messages = client.messages.any? { |message| !message.read }

      client.save!
    end
  end

  def down
    remove_column :clients, :last_contacted_at
    remove_column :clients, :has_unread_messages
  end
end
