class ReportingRelationship < ApplicationRecord
  CATEGORIES = APP_CONFIG['client_categories']

  belongs_to :user
  belongs_to :client
  belongs_to :client_status
  has_one :department, through: :user
  has_many :messages, dependent: :nullify

  scope :active, -> { where(active: true) }

  scope :full_name_contains, ->(str) { joins(:client).where("clients.first_name || ' ' || clients.last_name ILIKE CONCAT('%', ?, '%')", str) }

  validates :client, uniqueness: { scope: :user }
  validates :client, :user, presence: true
  validates :active, inclusion: { in: [true, false] }

  validates :category, inclusion: { in: CATEGORIES.keys }

  validate :unique_within_department

  attr_reader :matching_record

  def self.ransackable_scopes(_auth_object = nil)
    [:full_name_contains]
  end

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
    user.set_has_unread_messages

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

  def merge_with(rr_from, copy_name = false)
    ActiveRecord::Base.transaction do
      to_full_name = client.full_name
      from_full_name = rr_from.client.full_name

      if copy_name
        client.update!(first_name: rr_from.client.first_name, last_name: rr_from.client.last_name)
        NotificationSender.notify_users_of_changes(user: user, client: client)
      end

      Message.create_conversation_ends_marker(
        reporting_relationship: rr_from,
        full_name: from_full_name,
        phone_number: rr_from.client.display_phone_number
      )

      rr_from.messages.each do |message|
        message.like_message&.update!(reporting_relationship: self)
        message.update!(reporting_relationship: self)
      end

      copy_relationship_details(rr_from)

      update!(has_unread_messages: rr_from.has_unread_messages) if rr_from.has_unread_messages

      Message.create_merged_with_marker(
        reporting_relationship: self,
        from_full_name: from_full_name,
        to_full_name: to_full_name,
        from_phone_number: rr_from.client.display_phone_number,
        to_phone_number: client.display_phone_number
      )

      rr_from.update!(active: false)
    end
  end

  def display_name
    client.full_name
  end

  def timestamp
    (last_contacted_at || created_at).to_time.to_i
  end

  def deactivate
    update!(active: false)
    messages.scheduled.destroy_all
    mark_messages_read(update_user: true)
  end

  def mark_messages_read(update_user: false)
    update!(has_unread_messages: false)
    messages.unread.update(read: true)
    user.set_has_unread_messages if update_user
  end

  private

  def copy_relationship_details(rr_from)
    copy_last_contacted_at(rr_from)
    copy_category(rr_from)
    copy_notes(rr_from)
    copy_client_status(rr_from)
  end

  def copy_last_contacted_at(rr_from)
    return if rr_from.last_contacted_at.blank?
    return unless last_contacted_at.nil? || last_contacted_at < rr_from.last_contacted_at
    update!(last_contacted_at: rr_from.last_contacted_at)
  end

  def copy_category(rr_from)
    return unless rr_from.category != 'no_cat' && category == 'no_cat'
    update!(category: rr_from.category)
  end

  def copy_notes(rr_from)
    return unless rr_from.notes.present? && notes.blank?
    update!(notes: rr_from.notes)
  end

  def copy_client_status(rr_from)
    return unless rr_from.client_status.present? && client_status.blank?
    update!(client_status: rr_from.client_status)
  end

  def attachments
    Attachment.where(message: messages)
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
