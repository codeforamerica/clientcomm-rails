require 'simplecov'
require 'paperclip/matchers'

# Run code coverage and save to CircleCI's artifacts directory if we're on CircleCI
if ENV['CIRCLE_ARTIFACTS']
  SimpleCov.coverage_dir(File.join(ENV['CIRCLE_ARTIFACTS'], 'coverage'))
end
SimpleCov.start 'rails'

RSpec.configure do |config|
  unless ENV['CI']
    config.run_all_when_everything_filtered = true
    config.filter_run focus: true
  end

  config.example_status_persistence_file_path = 'tmp/examples.txt'

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  if config.files_to_run.one?
    config.default_formatter = 'doc'
  end

  config.include Paperclip::Shoulda::Matchers

  config.order = :random

  config.before(:each) do
    # Stub all posts to the mixpanel analytics API to respond with a 200 success
    stub_request(:post, /api.mixpanel.com/)
      .with(headers: { 'Accept' => '*/*', 'User-Agent' => 'Ruby' })
      .to_return(status: 200, body: 'stubbed response', headers: {})

    @mixpanel_requests = []
    @mixpanel_event_names = []
    WebMock.after_request do |request_signature|
      if request_signature.uri.host == 'api.mixpanel.com'
        parsed = JSON.parse(
          Base64.decode64(CGI.parse(request_signature.body)['data'][0])
        )
        @mixpanel_requests << { parsed['event'] => parsed['properties'] }
        @mixpanel_event_names << parsed['event']
      end
    end
  end

  config.after(:all) do
    I18n.locale = :en
  end
end
