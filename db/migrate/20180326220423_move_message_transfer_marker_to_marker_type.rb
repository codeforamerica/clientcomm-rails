class Message < ApplicationRecord
  MARKER_TRANSFER = 0
end

class MoveMessageTransferMarkerToMarkerType < ActiveRecord::Migration[5.1]
  def change
    reversible do |dir|
      dir.up do
        msgs = Message.all
        msgs.each do |msg|
          if msg.transfer_marker
            msg.marker_type = Message::MARKER_TRANSFER
            msg.save!
          end
        end
      end

      dir.down do
        msgs = Message.all
        msgs.each do |msg|
          if msg.marker_type == Message::MARKER_TRANSFER
            msg.transfer_marker = true
            msg.save!
          end
        end
      end
    end
  end
end
