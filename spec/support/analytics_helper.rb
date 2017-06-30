module AnalyticsHelper
  def expect_analytics_event_sequence(*event_names)
    # only the passed events happened, in the order passed
    expect(@mixpanel_event_names).to eq event_names
  end

  def expect_analytics_events_happened(*event_names)
    # all the passed events happend, independent of order
    event_names.each do |event_name|
      expect(@mixpanel_event_names).to include event_name
    end
  end

  def expect_analytics_events_not_happened(*event_names)
    # none of the passed events happened
    event_names.each do |event_name|
      expect(@mixpanel_event_names).not_to include event_name
    end
  end

  def expect_analytics_events(*event_hashes)
    # all the passed events happened, independent of order
    # and all the tracker data parameters and values match
    event_hashes.each do |event_description|
      event_name = event_description.keys.first
      event_properties = event_description.values.first
      found_request = @mixpanel_requests.find { |req| req.has_key? event_name }
      fail "Could not find #{event_name} in the requests" unless found_request
      expect(found_request[event_name]).to include event_properties
    end
  end
end
