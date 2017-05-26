class Message < ApplicationRecord
  belongs_to :client
  belongs_to :user
  after_create_commit { NewMessageBroadcastJob.perform_later self }
end
