class AdminUser < ApplicationRecord
  devise :database_authenticatable,
         :recoverable, :rememberable, :trackable, :validatable
end

class CourtDateCSV < ApplicationRecord
  belongs_to :admin_user
  belongs_to :user
end

class ChangeImage < ApplicationRecord
  belongs_to :admin_user
  belongs_to :user
end

class MoveAdminUsersToUsers < ActiveRecord::Migration[5.1]
  # rubocop:disable Metrics/MethodLength
  def change
    add_reference :court_date_csvs, :user, foreign_key: { to_table: :users }
    add_reference :change_images, :user, foreign_key: { to_table: :users }

    reversible do |dir|
      CourtDateCSV.reset_column_information
      ChangeImage.reset_column_information

      dir.up do
        AdminUser.all.each do |admin_user|
          user = User.find_by(email: admin_user.email)
          unless user.nil?
            user.update!(admin: true)
            next
          end

          temporary_password = SecureRandom.hex(4)
          user = User.create!(
            full_name: admin_user.email.split('@')[0],
            email: admin_user.email,
            password: temporary_password,
            password_confirmation: temporary_password,
            department: Department.first,
            admin: true
          )
          # rubocop:disable Rails/SkipsModelValidations
          user.update_attribute(:encrypted_password, admin_user.encrypted_password)
          # rubocop:enable Rails/SkipsModelValidations
          user.save!

          CourtDateCSV.where(admin_user: admin_user).each do |court_date_csv|
            court_date_csv.update!(user: user)
          end

          ChangeImage.where(admin_user: admin_user).each do |change_image|
            change_image.update!(user: user)
          end
        end
      end

      dir.down do
        User.where(admin: true).each do |user|
          admin_user = AdminUser.find_by(email: user.email)
          next unless admin_user.nil?

          temporary_password = SecureRandom.hex(4)
          admin_user = AdminUser.create!(
            email: user.email,
            password: temporary_password,
            password_confirmation: temporary_password
          )
          # rubocop:disable Rails/SkipsModelValidations
          admin_user.update_attribute(:encrypted_password, user.encrypted_password)
          # rubocop:enable Rails/SkipsModelValidations
          admin_user.save!

          CourtDateCSV.where(user: user).each do |court_date_csv|
            court_date_csv.update!(admin_user: admin_user)
          end

          ChangeImage.where(user: user).each do |change_image|
            change_image.update!(admin_user: admin_user)
          end
        end
      end
    end

    remove_reference :court_date_csvs, :admin_user, foreign_key: true
    remove_reference :change_images, :admin_user, foreign_key: true
  end
  # rubocop:enable Metrics/MethodLength
end
