class TextMessage < Message
  # TODO: add validations for twilio sid / etc.
  default_scope { where(type: %w[CourtReminder TextMessage]) }
end
