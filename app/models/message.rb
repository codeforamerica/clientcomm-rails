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
    # get the client based on the phone number
    client = Client.find_by!(phone_number: twilio_params[:From])
    # create a new message
    new_message_params = {
      client: client,
      user_id: client.user_id,
      number_to: ENV['TWILIO_PHONE_NUMBER'],
      number_from: twilio_params[:From],
      inbound: true,
      twilio_sid: twilio_params[:SmsSid],
      twilio_status: twilio_params[:SmsStatus],
      body: twilio_params[:Body]
    }
    new_message = Message.create!(new_message_params)

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
      scheduled_for: self.send_at
    }
  end

end
