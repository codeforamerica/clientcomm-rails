class ClientStatus < ApplicationRecord
  belongs_to :department

  validates_presence_of :name, :icon_color, :department
end
