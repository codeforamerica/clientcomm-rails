class Message < ApplicationRecord
  belongs_to :client
  belongs_to :user
  has_many :attachments

  scope :inbound, -> { where(inbound: true) }
  scope :outbound, -> { where(inbound: false) }
  scope :unread, -> { where(read: false) }

  INBOUND = 'inbound'
  OUTBOUND = 'outbound'
  READ = 'read'
  UNREAD = 'unread'

  def self.create_from_twilio!(twilio_params)
    phone_number = twilio_params[:From]

    client = Client.find_by(phone_number: phone_number)
    if client.nil?
      client = Client.create!(
          phone_number: phone_number,
          last_name: phone_number,
          user:  User.find_by_email!(ENV['UNCLAIMED_EMAIL'])
      )
    end

    new_message = Message.create!(
      client: client,
      user_id: client.user_id,
      number_to: ENV['TWILIO_PHONE_NUMBER'],
      number_from: phone_number,
      inbound: true,
      twilio_sid: twilio_params[:SmsSid],
      twilio_status: twilio_params[:SmsStatus],
      body: twilio_params[:Body]
    )

    twilio_params[:NumMedia].to_i.times.each do |i|
      new_message.attachments.create!({
        url: twilio_params["MediaUrl#{i}"],
        content_type: twilio_params["MediaContentType#{i}"]
      })
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
      scheduled_message: self.send_at.present?,
      message_date_scheduled: self.send_at,
      message_date_created: self.created_at
    }
  end

end
