class Client < ApplicationRecord
  belongs_to :user
  has_many :messages

  def full_name
    "#{first_name} #{last_name}"
  end

end
