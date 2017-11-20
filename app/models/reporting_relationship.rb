class ReportingRelationship < ApplicationRecord
  belongs_to :user
  belongs_to :client

  scope :active, -> { where(active: true) }

  validates :client, uniqueness: { scope: :user }
  validates :client, :user, presence: true
  validates :active, inclusion: { in: [true, false] }

  validate :unique_within_department

  attr_reader :matching_record

  private

  def unique_within_department
    @matching_record = ReportingRelationship
                       .active
                       .joins(:user)
                       .where(users: { department_id: user.try(:department_id) })
                       .where.not(user: user)
                       .find_by(client: client)

    errors.add(:client, :existing_dept_relationship) if @matching_record
  end
end
