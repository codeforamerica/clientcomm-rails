class AddClientStatusesTable < ActiveRecord::Migration[5.1]
  def change
    create_table :client_statuses do |t|
      t.string :name, null: false
    end

    add_reference :clients, :client_status, foreign_key: true

    ClientStatus.create!(name: 'Active')
    ClientStatus.create!(name: 'Training')
    ClientStatus.create!(name: 'Exited')

    FeatureFlag.create!(flag: 'client_status', enabled: false)
  end
end

class ClientStatus < ApplicationRecord
end
