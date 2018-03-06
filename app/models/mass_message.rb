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
end
