class Users::SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  def new
    super

    # only error for messages other than 'unauthenticated'
    unauth_msg = I18n.t('devise.failure.unauthenticated')
    has_error = !flash[:alert].nil? && flash[:alert] != unauth_msg
    if !has_error
      analytics_track(label: 'login_view')
    else
      analytics_track(label: 'login_error')
    end
  end

  # POST /resource/sign_in
  def create
    super

    # login is successful if we made it here
    analytics_track(label: 'login_success')
  end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end
end
