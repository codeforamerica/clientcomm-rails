class Message < ApplicationRecord
  belongs_to :client
  belongs_to :user

  scope :inbound, -> { where(inbound: true) }
  scope :outbound, -> { where(inbound: false) }
  scope :unread, -> { where(read: false) }

  INBOUND = 'inbound'
  OUTBOUND = 'outbound'
  READ = 'read'
  UNREAD = 'unread'
  
  def analytics_tracker_data
    {
      client_id: self.client.id,
      message_id: self.id,
      message_length: self.body.length
    }
  end

end
