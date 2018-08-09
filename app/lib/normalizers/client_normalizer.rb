module Normalizers
  class ClientNormalizer
    def initialize(client, params)
      @client = client
      @params = params
    end

    def update_client
      @client.update_attributes(@params)
      normalize_next_court_date_at if @params[:next_court_date_at].present?
    end

    def normalize_next_court_date_at
      @client.next_court_date_at = Date.strptime(@params[:next_court_date_at], '%m/%d/%Y')
    rescue ArgumentError
      @client.errors.add(:next_court_date_at, :invalid)
    end
  end
end
