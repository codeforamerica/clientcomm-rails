class MassMessage
  include ActiveModel::Model
  # For validations see:
  # http://railscasts.com/episodes/219-active-model?view=asciicast

  attr_accessor :user, :message, :clients

end
