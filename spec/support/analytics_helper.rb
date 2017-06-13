module AnalyticsHelper
  def expect_analytics_events(*events)
    expect(@mixpanel_event_names).to eq events 
  end
end
