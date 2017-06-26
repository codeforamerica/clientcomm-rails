class ApplicationController < ActionController::Base
  include AnalyticsHelper

  protect_from_forgery with: :exception
  before_action :set_visitor_id
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_filter :set_phone_number

  private

  # DEVISE

  # Allow additional parameters on devise's user class
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:full_name])
  end

  # ANALYTICS

  def set_visitor_id
    session[:visitor_id] ||= SecureRandom.hex(4)
  end

  # COMMON

  def set_phone_number
    @clientcomm_phone_number ||= PhoneNumberParser.format_for_display(ENV['TWILIO_PHONE_NUMBER'])
  end
end
