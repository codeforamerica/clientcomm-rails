class ReportingRelationship < ApplicationRecord
  belongs_to :user
  belongs_to :client

  validates_uniqueness_of :client, scope: :user
  validates_presence_of :client, :user, :active

  validate :unique_within_department

  attr_reader :matching_record

  private

  def unique_within_department
    @matching_record = ReportingRelationship
                       .joins(:user)
                       .where(users: { department_id: user.try(:department_id) })
                       .where.not(user: user)
                       .find_by(client: client)

    errors.add(:client, :existing_dept_relationship) if @matching_record
  end
end
