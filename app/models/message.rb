class Message < ApplicationRecord
  include Rails.application.routes.url_helpers
  belongs_to :client
  belongs_to :user
  has_many :attachments

  validates_presence_of :send_at, message: "That date didn't look right."
  validates_presence_of :body, unless: ->(message) { message.attachments.present? || message.inbound }
  validates_datetime :send_at, :before => :max_future_date

  scope :inbound, -> { where(inbound: true) }
  scope :outbound, -> { where(inbound: false) }
  scope :unread, -> { where(read: false) }
  scope :scheduled, -> { where('send_at >= ?', Time.now).order('send_at ASC') }
  scope :transfer_markers, -> { where(transfer_marker: true) }
  scope :messages, -> { where(transfer_marker: false) }

  INBOUND = 'inbound'
  OUTBOUND = 'outbound'
  READ = 'read'
  UNREAD = 'unread'
  ERROR = 'error'

  def self.create_transfer_markers(sending_user:, receiving_user:, client:)
    Message.create!(
      user: sending_user,
      body: I18n.t('messages.transferred_to', user_full_name: receiving_user.full_name),
      client: client,
      transfer_marker: true,
      read: true,
      send_at: Time.now,
      inbound: true,
      number_to: receiving_user.department.phone_number,
      number_from: client.phone_number
    )
    Message.create!(
      user: receiving_user,
      body: I18n.t('messages.transferred_from', user_full_name: sending_user.full_name,
                                                client_full_name: client.full_name),
      client: client,
      transfer_marker: true,
      read: true,
      send_at: Time.now,
      inbound: true,
      number_to: receiving_user.department.phone_number,
      number_from: client.phone_number
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
                       .order('reporting_relationships.updated_at DESC')
                       .find_by(reporting_relationships: { client: client })
      user ||= department.unclaimed_user
    end
    new_message = Message.new(
      client: client,
      user: user,
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
    if user == department.unclaimed_user && Message.where(client: client, user: department.users).count <= 1
      send_unclaimed_autoreply(client: client, department: department)
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

  def past_message?
    return false if send_at.nil?

    if send_at < time_buffer
      errors.add(:send_at, I18n.t('activerecord.errors.models.message.attributes.send_at.on_or_after'))

      true
    else
      false
    end
  end

  def reporting_relationship
    ReportingRelationship.find_by(user: user, client: client)
  end

  def first?
    self.client.messages.where(user: self.user).order(send_at: :desc).first == self
  end

  def self.send_unclaimed_autoreply(client:, department:)
    now = Time.now
    unclaimed_response = department.unclaimed_response
    unclaimed_response = I18n.t('message.unclaimed_response') if unclaimed_response.blank?
    message = Message.create!(
      client: client,
      user: department.unclaimed_user,
      body: unclaimed_response,
      number_from: department.phone_number,
      number_to: client.phone_number,
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

  def time_buffer
    Time.current - 5.minutes
  end

  def max_future_date
    Time.current + 1.year
  end
end
