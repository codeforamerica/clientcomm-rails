module RequestHelper
  def sign_in(user)
    post_params = { user: { email: user.email, password: user.password } }
    post user_session_path, params: post_params
  end
end
