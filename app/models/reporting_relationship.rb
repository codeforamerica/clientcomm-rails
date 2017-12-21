class ReportingRelationship < ApplicationRecord
  belongs_to :user
  belongs_to :client
  belongs_to :client_status

  scope :active, -> { where(active: true) }
  Department.all.find_each do |department|
    scope department.name, lambda {
      joins(:user).where(users: { department: department })
    }
  end

  validates :client, uniqueness: { scope: :user }
  validates :client, :user, presence: true
  validates :active, inclusion: { in: [true, false] }

  validate :unique_within_department

  attr_reader :matching_record

  def analytics_tracker_data
    {
      has_unread_messages: has_unread_messages,
      hours_since_contact: hours_since_contact,
      messages_all_count: messages.count,
      messages_received_count: messages.inbound.count,
      messages_sent_count: messages.outbound.count - messages.outbound.scheduled.count,
      messages_attachments_count: attachments.count,
      messages_scheduled_count: messages.scheduled.count,
      has_client_notes: notes.present?
    }
  end

  private

  def attachments
    Attachment.where(message: messages)
    # select * from attachments where attachments.message_id in [1, 2, 3]
  end

  def messages
    client.messages.where(user: user)
  end

  def hours_since_contact
    ((Time.now - (last_contacted_at || created_at)) / 3600).round
  end

  def unique_within_department
    @matching_record = ReportingRelationship
                       .active
                       .joins(:user)
                       .where(users: { department_id: user.try(:department_id) })
                       .where.not(user: user)
                       .find_by(client: client)

    errors.add(:client, :existing_dept_relationship) if @matching_record.present? && active
  end
end
