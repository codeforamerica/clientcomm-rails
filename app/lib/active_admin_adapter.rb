class ActiveAdminAdapter < ActiveAdmin::AuthorizationAdapter
  def authorized?(_action, _subject = nil)
    user.admin == true
  end
end
