class Message < ApplicationRecord
  MARKER_TRANSFER = 0
end

class MoveMessageTransferMarkerToMarkerType < ActiveRecord::Migration[5.1]
  def change
    add_column :messages, :marker_type, :int, null: true, default: nil
    add_index :messages, :marker_type

    reversible do |dir|
      dir.up do
        msg_count = Message.all.count
        Rails.logger.info "Migrating #{msg_count} messages"
        Message.reset_column_information
        Message.find_in_batches.with_index do |batch, i|
          Rails.logger.info "Migrating batch #{i} of #{msg_count / 1000}"
          batch.each do |msg|
            if msg.transfer_marker
              msg.marker_type = Message::MARKER_TRANSFER
              msg.save validate: false
            end
          end
        end
      end

      dir.down do
        msg_count = Message.all.count
        Rails.logger.info "Migrating #{msg_count} messages"
        Message.reset_column_information
        Message.find_in_batches.with_index do |batch, i|
          Rails.logger.info "Migrating batch #{i} of #{msg_count / 1000}"
          batch.each do |msg|
            if msg.marker_type == Message::MARKER_TRANSFER
              msg.transfer_marker = true
              msg.save validate: false
            end
          end
        end
      end
    end

    remove_column :messages, :transfer_marker, :boolean, default: false
  end
end
