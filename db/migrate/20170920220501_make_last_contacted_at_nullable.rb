class MakeLastContactedAtNullable < ActiveRecord::Migration[5.1]
  def up
    change_column :clients, :last_contacted_at, :datetime, null: true, default: nil
  end

  def down
    change_column :clients, :last_contacted_at, :datetime, null: false, default: -> { 'NOW()' }
  end
end
