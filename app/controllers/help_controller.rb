class HelpController < ApplicationController
  def index
    analytics_track(
      label: 'help_page_click'
    )

    raise(ActionController::RoutingError, 'No Help Link Set') if ENV['HELP_LINK'].blank?
    redirect_to ENV['HELP_LINK']
  end
end
