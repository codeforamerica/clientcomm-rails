module Users
  class RegistrationsController < Devise::RegistrationsController
    before_action :configure_account_update_params, only: [:update]

    def new
      redirect_to new_user_session_path
    end

    def create
      flash[:notice] = 'Contact an administrator for an account'
      redirect_to new_user_session_path
    end

    def update
      @user = User.find(current_user.id)
      updated = false

      if !form_params[:update_settings].nil?
        updated = @user.update(user_params)
      elsif !form_params[:change_password].nil?
        updated = update_resource(@user, user_params)
      end

      if updated
        flash[:notice] = 'Profile updated'
        bypass_sign_in @user
        redirect_to edit_user_registration_path
      else
        render 'edit'
      end
    end

    def destroy
    end

    protected

    def configure_account_update_params
      devise_parameter_sanitizer.permit(:account_update, keys: [:full_name, :phone_number])
    end

    def user_params
      devise_parameter_sanitizer.sanitize(:account_update)
    end

    def form_params
      params.permit(:update_settings, :change_password)
    end
  end
end
