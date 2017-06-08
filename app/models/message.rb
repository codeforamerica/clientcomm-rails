class Message < ApplicationRecord
  belongs_to :client
  belongs_to :user

  INBOUND = 'inbound'
  OUTBOUND = 'outbound'
  READ = 'read'
  UNREAD = 'unread'
end
