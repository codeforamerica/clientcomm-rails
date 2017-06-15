module AnalyticsHelper
  private

  # Send the provided tracking data through to the AnalyticsService
  def analytics_track(label:, data: {})
    # NOTE: May eventually want to diverge distinct and visitor IDs, so
    #       tracking them separately for now.

    tracking_data = data.merge(
      ip: visitor_ip,
      visitor_id: session[:visitor_id]
    )

    # prefer current_user_id if it was included in the data
    tracking_id = distinct_id tracking_data.slice(:current_user_id).values.first
    # but don't leave it in
    tracking_data = tracking_data.except(:current_user_id)

    user_agent = request.env['HTTP_USER_AGENT']

    AnalyticsService.instance.track(
      distinct_id: tracking_id,
      label: label,
      user_agent: user_agent,
      data: tracking_data
    )
  end

  def visitor_ip
    request.remote_ip || request.env['HTTP_X_FORWARDED_FOR']
  end

  def distinct_id(user_id = nil)
    user_id ||= !current_user.nil? ? current_user.id : session[:visitor_id]
    "#{id_prefix}-#{user_id}"
  end

  def id_prefix
    URI.parse(id_base).hostname.split(".")[0..1].join("_")
  end

  def id_base
    # NOTE: DEPLOY_BASE_URL is set by heroku
    request.base_url || ENV['DEPLOY_BASE_URL']
  end
end
