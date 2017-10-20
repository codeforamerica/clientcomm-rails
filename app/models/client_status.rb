class ClientStatus < ApplicationRecord
  validates_presence_of :followup_date, :name
end
