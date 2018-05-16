class Message < ApplicationRecord
end

class AddTypeToMessages < ActiveRecord::Migration[5.1]
  def up
    change_column :messages, :marker_type, :string
    Message.where(marker_type: '0').update(marker_type: 'TransferMarker')
    Message.where(marker_type: '1').update(marker_type: 'ClientEditMarker')
    Message.where(marker_type: '2').update(marker_type: 'CourtReminder')
    Message.where(marker_type: nil).update(marker_type: 'TextMessage')
    rename_column :messages, :marker_type, :type
    change_column :messages, :type, :string, null: false
  end

  def down
    rename_column :messages, :type, :marker_type
    Message.where(marker_type: 'TransferMarker').update(marker_type: '0')
    Message.where(marker_type: 'ClientEditMarker').update(marker_type: '1')
    Message.where(marker_type: 'CourtReminder').update(marker_type: '2')
    Message.where(marker_type: 'TextMessage').update(marker_type: nil)
    change_column :messages, :marker_type, 'integer USING CAST(marker_type AS integer)', null: true
  end
end
