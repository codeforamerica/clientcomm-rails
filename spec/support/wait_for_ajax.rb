module WaitForAjax
  def wait_for_ajax
    wait_for "all ajax requests to complete" do
      finished_all_ajax_requests?
    end
  end

  private

  def finished_all_ajax_requests?
    page.evaluate_script('window.$ !== undefined') &&
      page.evaluate_script('$.active').zero?
  end
end

RSpec.configure do |config|
  config.include WaitForAjax
end
