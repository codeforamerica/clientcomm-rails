class Users::PasswordsController < Devise::PasswordsController
  append_before_action :assert_reset_link_valid, only: :edit
  append_before_action :assert_reset_token_valid, only: :update

  def edit; end

  def update; end

  protected

  # Check the password token is valid
  def assert_reset_link_valid
    if !find_user_by_token(params[:reset_password_token])
      set_flash_message(:alert, :invalid_token)
      redirect_to new_user_password_path
    end
  end

  def assert_reset_token_valid
    if !find_user_by_token(params[:user][:reset_password_token])
      set_flash_message(:alert, :invalid_token)
      redirect_to new_user_password_path
    end
  end

  def find_user_by_token(token)
    encoded_token = Devise.token_generator.digest(User, :reset_password_token, token)
    user = User.find_by(reset_password_token: encoded_token)
    user if user && user.reset_password_period_valid?
  end
end
