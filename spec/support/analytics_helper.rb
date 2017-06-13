module AnalyticsHelper
  def expect_analytics_events(*events)
    if events.all? { |event| event.is_a? String }
      # it's an array of strings
      expect(@mixpanel_event_names).to eq events 
    else
      # it's an array of hashes
      events.each do |event_description|
        event_name = event_description.keys.first
        event_properties = event_description.values.first
        found_request = @mixpanel_requests.find { |req| req.has_key? event_name }
        fail "Could not find #{event_name} in the requests" unless found_request
        expect(found_request[event_name]).to include event_properties
      end
    end
  end
end
