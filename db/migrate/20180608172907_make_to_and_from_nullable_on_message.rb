class MakeToAndFromNullableOnMessage < ActiveRecord::Migration[5.1]
  def up
    change_column :messages, :number_to, :string, null: true
    change_column :messages, :number_from, :string, null: true
  end

  def down
    change_column :messages, :number_to, :string, null: false, default: '+15555555555'
    change_column :messages, :number_from, :string, null: false, default: '+15555555555'
  end
end
