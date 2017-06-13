class Message < ApplicationRecord
  belongs_to :client
  belongs_to :user

  scope :inbound, -> { where(inbound: true) }
  scope :unread, -> { where(read: false) }

  INBOUND = 'inbound'
  OUTBOUND = 'outbound'
  READ = 'read'
  UNREAD = 'unread'
end
