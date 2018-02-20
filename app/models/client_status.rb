class ClientStatus < ApplicationRecord
  belongs_to :department

  validates_presence_of :followup_date, :name, :icon_color
end
