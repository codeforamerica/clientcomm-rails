class TextMessage < Message
  validates :number_to, presence: true
  validates :number_from, presence: true

  before_validation :set_text_message, on: :create

  private

  def set_text_message
    return unless reporting_relationship

    if inbound
      self.number_from = reporting_relationship.client.phone_number
      self.number_to = reporting_relationship.user.department.phone_number
    else
      self.number_from = reporting_relationship.user.department.phone_number
      self.number_to = reporting_relationship.client.phone_number
    end
  end
end
