class Message < ApplicationRecord
  MARKER_TRANSFER = 0
end

class MoveMessageTransferMarkerToMarkerType < ActiveRecord::Migration[5.1]
  def change
    add_column :messages, :marker_type, :int, null: true, default: nil
    add_index :messages, :marker_type

    reversible do |dir|
      dir.up do
        Message.reset_column_information
        Message.find_each do |msg|
          if msg.transfer_marker
            msg.marker_type = Message::MARKER_TRANSFER
            msg.save!
          end
        end
      end

      dir.down do
        Message.reset_column_information
        Message.find_each do |msg|
          if msg.marker_type == Message::MARKER_TRANSFER
            msg.transfer_marker = true
            msg.save!
          end
        end
      end
    end

    remove_column :messages, :transfer_marker, :boolean, default: false
  end
end
