class Report < ApplicationRecord
  belongs_to :department

  validates :department, presence: true
  validates :email, presence: true

  def users
    department.users.active
  end
end
