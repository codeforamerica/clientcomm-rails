class AddClientStatusesTable < ActiveRecord::Migration[5.1]
  def change
    create_table :client_statuses do |t|
      t.string :name, null: false
    end

    add_reference :clients, :client_status, foreign_key: true
  end
end

class ClientStatus < ApplicationRecord
end
