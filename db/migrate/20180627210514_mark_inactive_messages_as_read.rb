class Message < ApplicationRecord
  belongs_to :reporting_relationship, class_name: 'ReportingRelationship', foreign_key: 'reporting_relationship_id'
end

class ReportingRelationship < ApplicationRecord
  has_many :messages, dependent: :nullify
end

class MarkInactiveMessagesAsRead < ActiveRecord::Migration[5.1]
  def change
    msgs = Message.joins(:reporting_relationship).where(read: false, reporting_relationships: { active: false })
    msgs.update(read: true)
  end
end
