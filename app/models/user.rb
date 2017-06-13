class User < ApplicationRecord
  has_many :clients, dependent: :destroy
  has_many :messages

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  def analytics_tracker_data
    {
      unread_messages: unread_message_count > 0,
      unread_messages_count: unread_message_count
    }
  end

  def unread_message_count
    # the number of messages received that are unread
    messages.unread.count
  end

end
