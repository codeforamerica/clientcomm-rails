module AnalyticsHelper
  private

  # Send the provided tracking data through to the AnalyticsService
  def analytics_track(label:, data: {})
    # NOTE: May eventually want to diverge distinct and visitor IDs, so
    #       tracking them separately for now.
    distinct_id = session[:visitor_id]
    tracking_data = data.merge(
      source: session[:source],
      visitor_id: session[:visitor_id]
    )
    user_agent = request.env['HTTP_USER_AGENT']

    AnalyticsService.instance.track(
      distinct_id: distinct_id.to_s,
      label: label,
      user_agent: user_agent,
      data: tracking_data
    )
  end
end
