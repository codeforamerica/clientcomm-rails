class Message < ApplicationRecord
  include Rails.application.routes.url_helpers

  belongs_to :reporting_relationship, class_name: 'ReportingRelationship', foreign_key: 'reporting_relationship_id'
  belongs_to :original_reporting_relationship, class_name: 'ReportingRelationship', foreign_key: 'original_reporting_relationship_id'
  has_one :client, through: :reporting_relationship
  has_one :user, through: :reporting_relationship
  has_many :attachments

  before_validation :set_original_reporting_relationship, on: :create

  validates_presence_of :send_at, message: "That date didn't look right."
  validates_presence_of :body, unless: ->(message) { message.attachments.present? || message.inbound }
  validates_presence_of :reporting_relationship
  validates_presence_of :original_reporting_relationship
  validates_datetime :send_at, :before => :max_future_date

  scope :inbound, -> { where(inbound: true) }
  scope :outbound, -> { where(inbound: false) }
  scope :unread, -> { where(read: false) }
  scope :scheduled, -> { where('send_at >= ?', Time.now).order('send_at ASC') }
  scope :transfer_markers, -> { where(marker_type: MARKER_TRANSFER) }
  scope :client_edit_markers, -> { where(marker_type: MARKER_CLIENT_EDIT) }
  scope :messages, -> { where(marker_type: nil) }

  class TransferClientMismatch < StandardError; end

  INBOUND = 'inbound'
  OUTBOUND = 'outbound'
  READ = 'read'
  UNREAD = 'unread'
  ERROR = 'error'

  MARKER_TRANSFER = 0
  MARKER_CLIENT_EDIT = 1

  def self.create_client_edit_markers(user:, phone_number:, reporting_relationships:)
    user_full_name = 'An admin user'
    user_id = nil
    if user.class.name.demodulize == 'User'
      user_full_name = user.full_name
      user_id = user.id
    end

    reporting_relationships.each do |rr|
      message_body = if rr.user_id == user_id
                       I18n.t(
                         'messages.phone_number_edited_by_you',
                         new_phone_number: phone_number
                       )
                     else
                       I18n.t(
                         'messages.phone_number_edited',
                         user_full_name: user_full_name,
                         new_phone_number: phone_number
                       )
                     end

      Message.create!(
        reporting_relationship: rr,
        body: message_body,
        marker_type: MARKER_CLIENT_EDIT,
        read: true,
        send_at: Time.now,
        inbound: true,
        number_to: rr.user.department.phone_number,
        number_from: rr.client.phone_number
      )
    end
  end

  def self.create_transfer_markers(sending_rr:, receiving_rr:)
    raise TransferClientMismatch unless sending_rr.client == receiving_rr.client

    Message.create!(
      reporting_relationship: sending_rr,
      body: I18n.t(
        'messages.transferred_to',
        user_full_name: receiving_rr.user.full_name
      ),
      marker_type: MARKER_TRANSFER,
      read: true,
      send_at: Time.now,
      inbound: true,
      number_to: sending_rr.user.department.phone_number,
      number_from: sending_rr.client.phone_number
    )
    Message.create!(
      reporting_relationship: receiving_rr,
      body: I18n.t(
        'messages.transferred_from',
        user_full_name: sending_rr.user.full_name,
        client_full_name: sending_rr.client.full_name
      ),
      marker_type: MARKER_TRANSFER,
      read: true,
      send_at: Time.now,
      inbound: true,
      number_to: receiving_rr.user.department.phone_number,
      number_from: receiving_rr.client.phone_number
    )
    true
  end

  def self.create_from_twilio!(twilio_params)
    from_phone_number = twilio_params[:From]
    to_phone_number = twilio_params[:To]

    client = Client.find_by(phone_number: from_phone_number)
    department = Department.find_by(phone_number: to_phone_number)

    if client.nil?
      user = department.unclaimed_user
      client = Client.create!(
        phone_number: from_phone_number,
        last_name: from_phone_number,
        users: [department.unclaimed_user]
      )
    else
      user = department.users
                       .active
                       .joins(:reporting_relationships)
                       .order('reporting_relationships.active DESC')
                       .order('reporting_relationships.updated_at DESC')
                       .find_by(reporting_relationships: { client: client })

      user ||= department.unclaimed_user
    end

    rr = ReportingRelationship.find_or_create_by(user: user, client: client)

    new_message = Message.new(
      reporting_relationship: rr,
      number_to: to_phone_number,
      number_from: from_phone_number,
      inbound: true,
      twilio_sid: twilio_params[:SmsSid],
      twilio_status: twilio_params[:SmsStatus],
      body: twilio_params[:Body],
      send_at: Time.current
    )
    twilio_params[:NumMedia].to_i.times.each do |i|
      attachment = Attachment.new

      attachment.media_remote_url = twilio_params["MediaUrl#{i}"]
      new_message.attachments << attachment
    end

    new_message.save!

    dept_rrs = ReportingRelationship.where(client: client, user: department.users)
    if user == department.unclaimed_user && Message.where(reporting_relationship: dept_rrs).count <= 1
      send_unclaimed_autoreply(rr: rr)
    end

    new_message
  end

  def analytics_tracker_data
    {
      client_id: self.client.id,
      message_id: self.id,
      message_length: self.body.length,
      current_user_id: self.user.id,
      attachments_count: self.attachments.count,
      message_date_scheduled: self.send_at,
      message_date_created: self.created_at,
      client_active: self.client.active(user: self.user),
      first_message: self.first?
    }
  end

  def marker?
    !marker_type.nil?
  end

  def transfer_marker?
    marker_type == MARKER_TRANSFER
  end

  def client_edit_marker?
    marker_type == MARKER_CLIENT_EDIT
  end

  def past_message?
    return false if send_at.nil?

    if send_at < time_buffer
      errors.add(:send_at, I18n.t('activerecord.errors.models.message.attributes.send_at.on_or_after'))

      true
    else
      false
    end
  end

  def first?
    reporting_relationship.messages.order(send_at: :asc).first == self
  end

  def self.send_unclaimed_autoreply(rr:)
    now = Time.now
    unclaimed_response = rr.department.unclaimed_response
    unclaimed_response = I18n.t('message.unclaimed_response') if unclaimed_response.blank?
    message = Message.create!(
      reporting_relationship: rr,
      body: unclaimed_response,
      number_from: rr.department.phone_number,
      number_to: rr.client.phone_number,
      send_at: now
    )
    ScheduledMessageJob.perform_later(message: message, send_at: now.to_i, callback_url: Rails.application.routes.url_helpers.incoming_sms_status_url)
  end

  def send_message
    sent = Time.now >= send_at
    MessageBroadcastJob.perform_now(message: self) if sent
    ScheduledMessageJob.set(wait_until: send_at).perform_later(message: self, send_at: send_at.to_i, callback_url: incoming_sms_status_url)
  end

  private

  def set_original_reporting_relationship
    self.original_reporting_relationship = reporting_relationship
  end

  def time_buffer
    Time.current - 5.minutes
  end

  def max_future_date
    Time.current + 1.year
  end
end
