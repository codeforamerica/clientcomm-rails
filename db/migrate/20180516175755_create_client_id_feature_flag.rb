class CreateClientIdFeatureFlag < ActiveRecord::Migration[5.1]
  def up
    FeatureFlag.find_or_create_by(flag: 'client_id_number').update!(enabled: false)
  end
end
