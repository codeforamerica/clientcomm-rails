require 'rails_helper.rb'
require_relative '../../db/migrate/20180731213237_move_admin_users_to_users.rb'

describe MoveAdminUsersToUsers do
  after do
    ActiveRecord::Migrator.migrate Rails.root.join('db', 'migrate'), @current_migration
    CourtDateCSV.reset_column_information
    ChangeImage.reset_column_information
  end

  describe '#up' do
    let!(:admin_user) { create :admin_user }

    before do
      @current_migration = ActiveRecord::Migrator.current_version
      ActiveRecord::Migrator.migrate Rails.root.join('db', 'migrate'), 20180731212736
      CourtDateCSV.reset_column_information
      ChangeImage.reset_column_information
    end

    subject do
      ActiveRecord::Migrator.migrate Rails.root.join('db', 'migrate'), 20180731213237
      CourtDateCSV.reset_column_information
      ChangeImage.reset_column_information
    end

    it 'users with admin flag set true are created for admin_users' do
      expect(User.all.count).to eq 0

      subject

      user = User.find_by(email: admin_user.email)

      expect(user).to_not eq nil
      expect(user.admin).to eq true
      expect(user.encrypted_password).to eq admin_user.encrypted_password
    end

    context 'a user with the same email address already exists' do
      let!(:existing_user) { create :user, email: admin_user.email, admin: false }

      it 'does not create a new user but does set the admin flag true' do
        expect { subject }.to_not raise_error(ActiveRecord::RecordInvalid)

        users = User.where(email: admin_user.email)
        expect(users.count).to eq 1
        expect(users.first.admin).to eq true
      end
    end

    context 'the admin user is associated with a court date csv' do
      let(:filename) { 'court_dates.csv' }
      let!(:court_date_csv) { CourtDateCSV.create!(file: File.new("./spec/fixtures/#{filename}"), admin_user: admin_user) }

      it 'creates a new association pointing to the user' do
        subject

        user = User.find_by(email: admin_user.email)
        expect(court_date_csv.reload.user).to eq user
      end
    end

    context 'the admin user is associated with a change image' do
      let(:filename) { 'fluffy_cat.jpg' }
      let!(:change_image) { ChangeImage.create!(file: File.new("./spec/fixtures/#{filename}"), admin_user: admin_user) }

      it 'creates a new association pointing to the user' do
        subject

        user = User.find_by(email: admin_user.email)
        expect(change_image.reload.user).to eq user
      end
    end
  end

  describe '#down' do
    let!(:user) { create :user, admin: true }

    before do
      @current_migration = ActiveRecord::Migrator.current_version
      ActiveRecord::Migrator.migrate Rails.root.join('db', 'migrate'), 20180731213237
      CourtDateCSV.reset_column_information
      ChangeImage.reset_column_information
    end

    subject do
      ActiveRecord::Migrator.migrate Rails.root.join('db', 'migrate'), 20180731212736
      CourtDateCSV.reset_column_information
      ChangeImage.reset_column_information
    end

    it 'admin users are created for users with admin flag set true' do
      expect(AdminUser.all.count).to eq 0

      subject

      admin_user = AdminUser.find_by(email: user.email)

      expect(admin_user).to_not eq nil
      expect(admin_user.encrypted_password).to eq user.encrypted_password
    end

    context 'an admin user with the same email address already exists' do
      let!(:existing_admin_user) { create :admin_user, email: user.email }

      it 'does not create a new admin user' do
        expect { subject }.to_not raise_error(ActiveRecord::RecordInvalid)

        admin_users = AdminUser.where(email: user.email)
        expect(admin_users.count).to eq 1
      end
    end

    context 'the user is associated with a court date csv' do
      let(:filename) { 'court_dates.csv' }
      let!(:court_date_csv) { CourtDateCSV.create!(file: File.new("./spec/fixtures/#{filename}"), user: user) }

      it 'creates a new association pointing to the admin user' do
        subject

        admin_user = AdminUser.find_by(email: user.email)
        expect(court_date_csv.reload.admin_user).to eq admin_user
      end
    end

    context 'the user is associated with a change image' do
      let(:filename) { 'fluffy_cat.jpg' }
      let!(:change_image) { ChangeImage.create!(file: File.new("./spec/fixtures/#{filename}"), user: user) }

      it 'creates a new association pointing to the user' do
        subject

        admin_user = AdminUser.find_by(email: user.email)
        expect(change_image.reload.admin_user).to eq admin_user
      end
    end
  end
end
