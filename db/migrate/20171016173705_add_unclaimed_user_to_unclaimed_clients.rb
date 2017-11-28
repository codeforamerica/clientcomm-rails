class AddUnclaimedUserToUnclaimedClients < ActiveRecord::Migration[5.1]
  def change
    Client.where(user: nil).each do |client|
      User.find_by(email: ENV['UNCLAIMED_EMAIL']).clients << client
    end
  end
end
