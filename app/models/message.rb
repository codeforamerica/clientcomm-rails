class Message < ApplicationRecord
  include Rails.application.routes.url_helpers

  belongs_to :reporting_relationship, class_name: 'ReportingRelationship', foreign_key: 'reporting_relationship_id'
  belongs_to :original_reporting_relationship, class_name: 'ReportingRelationship', foreign_key: 'original_reporting_relationship_id'
  belongs_to :like_message, class_name: 'Message', foreign_key: 'like_message_id'
  has_one :client, through: :reporting_relationship
  has_one :user, through: :reporting_relationship
  has_many :attachments, dependent: :nullify

  before_validation :set_original_reporting_relationship, on: :create

  validates :send_at, presence: { message: "That date didn't look right." }
  validates :body, presence: { unless: ->(message) { message.attachments.present? || message.inbound } }
  validates :reporting_relationship, presence: true
  validates :original_reporting_relationship, presence: true
  validates_datetime :send_at, before: :max_future_date

  validates :type, exclusion: { in: %w[Message] }

  validates :body, length: { maximum: 1600 }

  validate :same_reporting_relationship_as_like_message

  scope :inbound, -> { where(inbound: true) }
  scope :outbound, -> { where(inbound: false) }
  scope :unread, -> { where(read: false) }
  scope :scheduled, -> { where('send_at >= ?', Time.zone.now).order('send_at ASC') }
  scope :messages, -> { where(type: [TextMessage.to_s, CourtReminder.to_s]) }

  class TransferClientMismatch < StandardError; end

  INBOUND = 'inbound'.freeze
  OUTBOUND = 'outbound'.freeze
  READ = 'read'.freeze
  UNREAD = 'unread'.freeze
  ERROR = 'error'.freeze

  def self.create_client_edit_markers(user:, phone_number:, reporting_relationships:)
    user_full_name = I18n.t('messages.admin_user_description')
    user_id = nil
    if user.class.name.demodulize == 'User'
      user_full_name = user.full_name
      user_id = user.id
    end

    display_phone_number = PhoneNumberParser.format_for_display(phone_number)

    reporting_relationships.each do |rr|
      message_body = if rr.user_id == user_id
                       I18n.t(
                         'messages.phone_number_edited_by_you',
                         new_phone_number: display_phone_number
                       )
                     else
                       I18n.t(
                         'messages.phone_number_edited',
                         user_full_name: user_full_name,
                         new_phone_number: display_phone_number
                       )
                     end

      ClientEditMarker.create!(
        reporting_relationship: rr,
        body: message_body
      )
    end
  end

  def self.create_transfer_markers(sending_rr:, receiving_rr:)
    raise TransferClientMismatch unless sending_rr.client == receiving_rr.client

    TransferMarker.create!(
      reporting_relationship: sending_rr,
      body: I18n.t(
        'messages.transferred_to',
        user_full_name: receiving_rr.user.full_name
      )
    )
    TransferMarker.create!(
      reporting_relationship: receiving_rr,
      body: I18n.t(
        'messages.transferred_from',
        user_full_name: sending_rr.user.full_name,
        client_full_name: sending_rr.client.full_name
      )
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

    new_message = TextMessage.new(
      reporting_relationship: rr,
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
      client_id: client.id,
      message_id: id,
      message_length: body.length,
      current_user_id: user.id,
      attachments_count: attachments.count,
      message_date_scheduled: send_at,
      message_date_created: created_at,
      client_active: client.active(user: user),
      first_message: first?,
      positive_template: like_message.present?,
      positive_template_type: positive_template_type,
      positive_template_message_id: like_message&.id,
      created_by: created_by_type
    }
  end

  def marker?
    [CourtReminder.to_s, TextMessage.to_s].exclude? type
  end

  def transfer_marker?
    type == TransferMarker.to_s
  end

  def client_edit_marker?
    type == ClientEditMarker.to_s
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
    now = Time.zone.now
    unclaimed_response = rr.department.unclaimed_response
    unclaimed_response = I18n.t('message.unclaimed_response') if unclaimed_response.blank?
    message = TextMessage.create!(
      reporting_relationship: rr,
      body: unclaimed_response,
      send_at: now
    )
    ScheduledMessageJob.perform_later(message: message, send_at: now.to_i, callback_url: Rails.application.routes.url_helpers.incoming_sms_status_url)
  end

  def send_message
    sent = Time.zone.now >= send_at
    MessageBroadcastJob.perform_now(message: self) if sent
    ScheduledMessageJob.set(wait_until: send_at).perform_later(message: self, send_at: send_at.to_i, callback_url: incoming_sms_status_url)
  end

  private

  def same_reporting_relationship_as_like_message
    return unless like_message
    errors.add(:like_message, :different_reporting_relationship) if like_message.reporting_relationship != reporting_relationship
  end

  def positive_template_type
    body if like_message.present?
  end

  def set_original_reporting_relationship
    self.original_reporting_relationship = reporting_relationship
  end

  def time_buffer
    Time.current - 5.minutes
  end

  def max_future_date
    Time.current + 1.year
  end

  def created_by_type
    if type == CourtReminder.to_s
      'auto-uploader'
    elsif type == TextMessage.to_s
      if inbound
        'client'
      else
        'user'
      end
    end
  end
end
