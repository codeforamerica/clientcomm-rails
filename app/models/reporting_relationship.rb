class ReportingRelationship < ApplicationRecord
  CATEGORIES = APP_CONFIG['client_categories']

  belongs_to :user
  belongs_to :client
  belongs_to :client_status
  has_one :department, through: :user
  has_many :messages, dependent: :nullify

  scope :active, -> { where(active: true) }

  validates :client, uniqueness: { scope: :user }
  validates :client, :user, presence: true
  validates :active, inclusion: { in: [true, false] }

  validates :category, inclusion: { in: CATEGORIES.keys }

  validate :unique_within_department

  attr_reader :matching_record

  def self.categories_linked_list
    links = {}
    last_cat, last_info = CATEGORIES.first
    CATEGORIES.to_a.reverse.each do |name, info|
      links[name] = last_info.merge(name: last_cat)
      last_cat = name
      last_info = info
    end
    links
  end

  def category_info
    CATEGORIES[category]
  end

  def analytics_tracker_data
    {
      has_unread_messages: has_unread_messages,
      hours_since_contact: hours_since_contact,
      messages_all_count: messages.messages.count,
      messages_received_count: messages.messages.inbound.count,
      messages_sent_count: messages.outbound.count - messages.outbound.scheduled.count,
      messages_attachments_count: attachments.count,
      messages_scheduled_count: messages.scheduled.count,
      has_client_notes: notes.present?
    }
  end

  def transfer_to(new_reporting_relationship)
    # Requires that current RR is active and transfer_user is in same dept.
    # If not it will behave improperly and have more than one active
    new_reporting_relationship.active = true
    self.active = false
    self.has_unread_messages = false
    ActiveRecord::Base.transaction do
      save!
      new_reporting_relationship.save!
    end

    messages.scheduled.update(reporting_relationship: new_reporting_relationship)
    messages.messages.unread.update(read: true)
    if user == new_reporting_relationship.user.department.unclaimed_user
      messages.update(reporting_relationship: new_reporting_relationship)
    end
    new_reporting_relationship.client_status = client_status
    new_reporting_relationship.save!
    Message.create_transfer_markers(receiving_rr: new_reporting_relationship, sending_rr: self)
  end

  def display_name
    client.full_name
  end

  def timestamp
    (last_contacted_at || created_at).to_time.to_i
  end

  private

  def attachments
    Attachment.where(message: messages)
    # select * from attachments where attachments.message_id in [1, 2, 3]
  end

  def hours_since_contact
    ((Time.zone.now - (last_contacted_at || created_at)) / 3600).round
  end

  def unique_within_department
    @matching_record = ReportingRelationship
                       .active
                       .joins(:user)
                       .where(users: { department_id: user.try(:department_id) })
                       .where.not(user: user)
                       .find_by(client: client)

    errors.add(:client, :existing_dept_relationship, user_full_name: @matching_record.user.full_name) if @matching_record.present? && active
  end
end
