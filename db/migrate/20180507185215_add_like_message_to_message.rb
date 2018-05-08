class AddLikeMessageToMessage < ActiveRecord::Migration[5.1]
  def change
    add_reference :messages, :like_message, foreign_key: { to_table: :messages }
  end
end
