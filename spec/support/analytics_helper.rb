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

  def expect_most_recent_analytics_event(event_hash)
    event_name = event_hash.keys.first
    event_properties = event_hash[event_name]

    expect(@mixpanel_requests.last[event_name]).to include(event_properties)
  end

  def expect_analytics_events(*event_hashes)
    # all the passed events happened, independent of order
    # and all the tracker data parameters and values match
    event_hashes.each do |event_description|
      event_name = event_description.keys.first
      event_properties = event_description.values.first
      found_request = @mixpanel_requests.find { |req| req.key? event_name }
      fail "Could not find #{event_name} in the requests" unless found_request
      expect(found_request[event_name]).to include event_properties
    end
  end

  def expect_analytics_events_with_keys(*event_arrays)
    # all the passed events happened with these keys
    # key values are not tested
    event_arrays.each do |event_names|
      event_name = event_names.keys.first
      event_properties = event_names.values.first
      found_request = @mixpanel_requests.find { |req| req.key? event_name }
      fail "Could not find #{event_name} in the requests" unless found_request
      # byebug
      event_properties.each do |key|
        expect(found_request[event_name].keys).to include key
      end
    end
  end
end
