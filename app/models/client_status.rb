class ClientStatus < ApplicationRecord
  belongs_to :department

  validates :name, :icon_color, :department, presence: true
end
