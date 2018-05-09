class TrackingEventsController < ApplicationController
  before_action :authenticate_user!
  skip_after_action :intercom_rails_auto_include

  def create
    analytics_track(label: label, data: data)
  end

  private

  def label
    params.require(:label)
  end

  def data
    params.require(:data).permit!
  end
end
