class AddReadToMessages < ActiveRecord::Migration[5.0]
  def change
    add_column :messages, :read, :boolean, default: false

    # read defaults to false, but all messages that exist when the migration
    # happens should have read = true
    Message.update(read: true)
  end
end
