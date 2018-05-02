class MassMessage
  include ActiveModel::Model
  # For validations see:
  # http://railscasts.com/episodes/219-active-model?view=asciicast

  validates :message, :reporting_relationships, presence: true

  attr_accessor :user, :message, :send_at, :reporting_relationships

  def initialize(attributes = {})
    super
    @reporting_relationships ||= []
    @reporting_relationships.map!(&:to_i)
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
