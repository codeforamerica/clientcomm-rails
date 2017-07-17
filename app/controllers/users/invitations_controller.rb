class Users::InvitationsController < Devise::InvitationsController

  before_action :update_sanitized_params, only: :update

  def new
    super

    analytics_track(label: 'invite_view')
  end

  protected

  def update_sanitized_params
    devise_parameter_sanitizer.permit(:accept_invitation, keys: [:full_name])
  end
end
