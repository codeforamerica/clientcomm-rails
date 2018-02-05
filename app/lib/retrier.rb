class Retrier
  def initialize(retries:, errors:)
    yield
  rescue *errors
    retries -= 1
    retry if retries.positive?
  end
end
