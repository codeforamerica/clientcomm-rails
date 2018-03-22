class User < ApplicationRecord
  has_many :reporting_relationships
  has_many :clients, through: :reporting_relationships
  has_many :messages
  has_many :templates
end

class Client < ApplicationRecord
  has_many :reporting_relationships, dependent: :nullify
  has_many :users, through: :reporting_relationships
  has_many :messages, -> { order(send_at: :asc) }, inverse_of: :client

  scope :active, lambda {
    joins(:reporting_relationships)
      .where(reporting_relationships: { active: true })
      .distinct
  }

  validates_associated :reporting_relationships
  accepts_nested_attributes_for :reporting_relationships

  before_validation :normalize_phone_number, if: :phone_number_changed?
  validate :service_accepts_phone_number, if: :phone_number_changed?

  validates_presence_of :last_name, :phone_number
  validates_uniqueness_of :phone_number
end

class Message < ApplicationRecord
  belongs_to :reporting_relationship, class_name: 'ReportingRelationship', foreign_key: 'reporting_relationship_id'
  belongs_to :original_reporting_relationship, class_name: 'ReportingRelationship', foreign_key: 'original_reporting_relationship_id'
  belongs_to :client
  belongs_to :user
end

class ReportingRelationship < ApplicationRecord
  belongs_to :user
  belongs_to :client

  validates :client, uniqueness: { scope: :user }
  validates :client, :user, presence: true
  validates :active, inclusion: { in: [true, false] }
end

class AddReportingRelationshipToMessage < ActiveRecord::Migration[5.1]
  def change
    add_reference :messages, :reporting_relationship, foreign_key: { to_table: :reporting_relationships }
    add_reference :messages, :original_reporting_relationship, foreign_key: { to_table: :reporting_relationships }
    reversible do |dir|
      dir.up do
        Message.reset_column_information
        msgs = Message.all
        msgs.each do |msg|
          reporting_relationship = ReportingRelationship.find_by(user: msg.user, client: msg.client)
          if reporting_relationship.blank?
            reporting_relationship = ReportingRelationship.create!(
              user: msg.user,
              client: msg.client,
              active: false
            )
          end
          msg.reporting_relationship = reporting_relationship
          msg.original_reporting_relationship = reporting_relationship
          msg.save!
        end
      end
      dir.down do
        Message.reset_column_information
        msgs = Message.all
        msgs.each do |msg|
          msg.user = msg.reporting_relationship.user
          msg.client = msg.reporting_relationship.client
          msg.save!
        end
      end
    end
    change_column :messages, :original_reporting_relationship_id, :bigint, null: false
    remove_reference :messages, :user, index: true, foreign_key: true
    remove_reference :messages, :client, index: true, foreign_key: true
  end
end
