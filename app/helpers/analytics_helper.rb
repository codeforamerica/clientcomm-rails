module AnalyticsHelper
  # Send the provided tracking data through to the AnalyticsService
  def analytics_track(label:, data: {})
    # NOTE: May eventually want to diverge distinct and visitor IDs, so
    #       tracking them separately for now.

    tracking_data = data.merge(
      ip: visitor_ip,
      deploy: deploy_prefix,
      visitor_id: visitor_id,
      treatment_group: treatment_group
    ).merge(utm)
    tracking_id = distinct_id
    tracking_data = tracking_data.except(:current_user_id)

    AnalyticsService.track(
      distinct_id: tracking_id,
      label: label,
      user_agent: user_agent,
      data: tracking_data
    )
  end

  private

  def treatment_group
    current_user&.treatment_group
  end

  def utm
    utm_params = {}
    request.GET.each do |k, v|
      utm_params[k] = v if /^utm_(.*)/.match?(k)
    end
    utm_params
  end

  def user_agent
    request.env['HTTP_USER_AGENT']
  rescue NameError
    nil
  end

  def visitor_id
    session[:visitor_id]
  rescue NameError
    nil
  end

  def visitor_ip
    request.remote_ip
  rescue NameError
    nil
  end

  def distinct_id
    if current_user
      "#{deploy_prefix}-#{current_user.id}"
    else
      "#{deploy_prefix}-#{visitor_id}"
    end
  end

  def deploy_prefix
    URI.parse(ENV['DEPLOY_BASE_URL']).hostname.split('.')[0..1].join('_')
  end
end
