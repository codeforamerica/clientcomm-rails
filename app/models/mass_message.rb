class MassMessage
  include ActiveModel::Model
  # For validations see:
  # http://railscasts.com/episodes/219-active-model?view=asciicast

  validates_presence_of :message, :clients

  attr_accessor :user, :message, :send_at, :clients

  def initialize(attributes = {})
    super
    @clients ||= []
    @clients.map!(&:to_i)
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

  private

  def time_buffer
    Time.current - 5.minutes
  end
end
