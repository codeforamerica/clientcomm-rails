class Transfer
  include ActiveModel::Model
  # For validations see:
  # http://railscasts.com/episodes/219-active-model?view=asciicast

  validates :user_id, :client_id, presence: true

  attr_accessor :user_id, :client_id, :note

  def initialize(attributes = {})
    super
  end

  def apply
    client = Client.find(@client_id)
    user = User.find(@user_id)
    old_user_id = client.active_users.find_by(department: user.department).id
    ReportingRelationship.find_by(user: old_user_id, client_id: @client_id).update!(active: false)
    ReportingRelationship.find_or_create_by(user_id: @user_id, client_id: @client_id).update!(active: true)
  end
end
