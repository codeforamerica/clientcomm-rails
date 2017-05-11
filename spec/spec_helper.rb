RSpec.configure do |config|
  unless ENV['CI']
    config.run_all_when_everything_filtered = true
    config.filter_run focus: true
  end

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

  config.order = :random

  config.before(:each) do
    # Stub all posts to the mixpanel analytics API to respond with a 200 success
    stub_request(:post, /api.mixpanel.com/)
      .with(headers: { 'Accept' => '*/*', 'User-Agent' => 'Ruby' })
      .to_return(status: 200, body: "stubbed response", headers: {})
  end

  config.after(:each) do
    # Prevents any test doubles for this singleton class from being re-used
    # across examples, which is not supported.
    AnalyticsService.instance_variable_set(:@singleton__instance__, nil)
  end

  config.after(:all) do
    I18n.locale = :en
  end
end
