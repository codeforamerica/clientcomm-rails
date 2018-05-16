require 'rails_helper'

describe CourtRemindersImporter do
  describe 'self.generate_reminders', active_job: true do
    subject { described_class.generate_reminders(court_dates, court_locs) }

    let(:court_dates) do
      [
        { 'ofndr_num' => '111', '(expression)' => '1337D', 'lname' => 'HANES',  'crt_dt' => '5/8/2018', 'crt_tm' => '8:30', 'crt_rm' => '1' },
        { 'ofndr_num' => '112', '(expression)' => '8675R', 'lname' => 'SIMON',  'crt_dt' => '5/9/2018', 'crt_tm' => '9:40', 'crt_rm' => '2' },
        { 'ofndr_num' => '113', '(expression)' => '1776B', 'lname' => 'BARTH',  'crt_dt' => '5/10/2018', 'crt_tm' => '14:30', 'crt_rm' => '3' },
        { 'ofndr_num' => 'not found', '(expression)' => '1776B', 'lname' => 'BARTH', 'crt_dt' => '5/10/2018', 'crt_tm' => '14:30', 'crt_rm' => '3' }
      ]
    end

    let(:court_locs) do
      {
        '1337D' => 'RIVENDALE DISTRICT (444 hobbit lane)',
        '8675R' => 'ROHAN COURT (123 Horse Lord Blvd)',
        '1776B' => 'MORDER COUNTY (666 Doom rd)'
      }
    end

    let!(:rr1) { create :reporting_relationship, notes: '111' }
    let!(:rr2) { create :reporting_relationship, notes: '112' }
    let!(:rr3) { create :reporting_relationship, notes: '113' }
    let!(:rr_irrelevant) { create :reporting_relationship, notes: 'not a ctrack number' }

    before do
      travel_to Time.strptime('5/1/2018 8:30 -0600', '%m/%d/%Y %H:%M %z')
    end

    after do
      travel_back
    end

    it 'schedules messages for relevant reporting relationships' do
      subject

      expect(rr1.messages.scheduled).to_not be_empty
      body1 = I18n.t(
        'message.auto_court_reminder',
        location: 'RIVENDALE DISTRICT (444 hobbit lane)',
        date: '5/8/2018',
        time: '8:30am',
        room: '1'
      )
      time1 = Time.strptime('5/7/2018 8:30 -0600', '%m/%d/%Y %H:%M %z')
      message1 = rr1.messages.scheduled.last
      expect(message1.body).to eq body1
      expect(message1.send_at).to eq time1
      expect(ScheduledMessageJob).to have_been_enqueued
        .at(time1)
        .with(message: message1, send_at: Integer, callback_url: String)

      expect(rr2.messages.scheduled).to_not be_empty
      body2 = I18n.t(
        'message.auto_court_reminder',
        location: 'ROHAN COURT (123 Horse Lord Blvd)',
        date: '5/9/2018',
        time: '9:40am',
        room: '2'
      )
      time2 = Time.strptime('5/8/2018 9:40 -0600', '%m/%d/%Y %H:%M %z')
      message2 = rr2.messages.scheduled.last
      expect(message2.body).to eq body2
      expect(message2.send_at).to eq time2
      expect(ScheduledMessageJob).to have_been_enqueued
        .at(time2)
        .with(message: message2, send_at: Integer, callback_url: String)

      expect(rr3.messages.scheduled).to_not be_empty
      body3 = I18n.t(
        'message.auto_court_reminder',
        location: 'MORDER COUNTY (666 Doom rd)',
        date: '5/10/2018',
        time: '2:30pm',
        room: '3'
      )
      time3 = Time.strptime('5/9/2018 14:30 -0600', '%m/%d/%Y %H:%M %z')
      message3 = rr3.messages.scheduled.last
      expect(message3.body).to eq body3
      expect(message3.send_at).to eq time3
      expect(ScheduledMessageJob).to have_been_enqueued
        .at(time3)
        .with(message: message3, send_at: Integer, callback_url: String)

      expect(rr_irrelevant.messages.scheduled).to be_empty
    end

    context 'there is a bad date' do
      let(:court_dates) do
        [
          { 'ofndr_num' => '111', '(expression)' => '1337D', 'lname' => 'HANES',  'crt_dt' => '5/8/2018', 'crt_tm' => '8:30', 'crt_rm' => '1' },
          { 'ofndr_num' => '112', '(expression)' => '8675R', 'lname' => 'SIMON',  'crt_dt' => '5/42/2018', 'crt_tm' => '9:40', 'crt_rm' => '2' },
          { 'ofndr_num' => '113', '(expression)' => '1776B', 'lname' => 'BARTH',  'crt_dt' => '5/10/2018', 'crt_tm' => '14:30', 'crt_rm' => '3' }
        ]
      end

      let!(:existing_reminder) { create :court_reminder, reporting_relationship: rr1, send_at: Time.zone.now + 2.days }

      it 'does not save any  messages' do
        expect { subject }.to raise_error(ArgumentError, 'invalid strptime format - `%m/%d/%Y %H:%M %z\'')

        expect(rr1.messages.scheduled).to contain_exactly(existing_reminder)
        expect(rr2.messages.scheduled).to be_empty
        expect(rr3.messages.scheduled).to be_empty
      end
    end

    context 'there are already court date reminders' do
      let!(:existing_reminder) { create :message, reporting_relationship: rr1, send_at: Time.zone.now + 2.days, type: Message::AUTO_COURT_REMINDER }

      it 'deletes all existing reminders' do
        subject
        expect(rr1.messages.scheduled).to_not include(existing_reminder)
      end
    end

    context 'there are court dates in the past' do
      let(:court_dates) do
        [
          { 'ofndr_num' => '111', '(expression)' => '1337D', 'lname' => 'HANES',  'crt_dt' => '1/8/2018', 'crt_tm' => '8:30', 'crt_rm' => '1' },
          { 'ofndr_num' => '112', '(expression)' => '8675R', 'lname' => 'SIMON',  'crt_dt' => '5/9/2018', 'crt_tm' => '9:40', 'crt_rm' => '2' },
          { 'ofndr_num' => '113', '(expression)' => '1776B', 'lname' => 'BARTH',  'crt_dt' => '5/10/2018', 'crt_tm' => '14:30', 'crt_rm' => '3' },
          { 'ofndr_num' => 'not found', '(expression)' => '1776B', 'lname' => 'BARTH', 'crt_dt' => '5/10/2018', 'crt_tm' => '14:30', 'crt_rm' => '3' }
        ]
      end

      it 'ignores past court dates' do
        subject

        expect(rr1.messages).to be_empty
      end
    end

    context 'there are two RRs with the same ctrack' do
      let!(:rr4) { create :reporting_relationship, notes: '111' }

      before do
        create :message, send_at: Time.zone.now - 1.day, reporting_relationship: rr4
      end

      it 'picks the rr that was most recently contacted' do
        subject

        expect(rr1.messages.scheduled).to be_empty

        expect(rr4.messages.scheduled).to_not be_empty
        body = I18n.t(
          'message.auto_court_reminder',
          location: 'RIVENDALE DISTRICT (444 hobbit lane)',
          date: '5/8/2018',
          time: '8:30am',
          room: '1'
        )
        time = Time.strptime('5/7/2018 8:30 -0600', '%m/%d/%Y %H:%M %z')
        message = rr4.messages.scheduled.last
        expect(message.body).to eq body
        expect(message.send_at).to eq time
        expect(ScheduledMessageJob).to have_been_enqueued
          .at(time)
          .with(message: message, send_at: Integer, callback_url: String)
      end

      context 'two rrs have both been contacted' do
        before do
          create :message, send_at: Time.zone.now - 3.days, reporting_relationship: rr1
          create :message, send_at: Time.zone.now - 1.day, reporting_relationship: rr4
        end

        it 'picks the rr that was most recently contacted' do
          subject

          expect(rr1.messages.scheduled).to be_empty

          expect(rr4.messages.scheduled).to_not be_empty
          body = I18n.t(
            'message.auto_court_reminder',
            location: 'RIVENDALE DISTRICT (444 hobbit lane)',
            date: '5/8/2018',
            time: '8:30am',
            room: '1'
          )
          time = Time.strptime('5/7/2018 8:30 -0600', '%m/%d/%Y %H:%M %z')
          message = rr4.messages.scheduled.last
          expect(message.body).to eq body
          expect(message.send_at).to eq time
          expect(ScheduledMessageJob).to have_been_enqueued
            .at(time)
            .with(message: message, send_at: Integer, callback_url: String)
        end
      end
    end
  end

  describe 'self.generate_locations_hash' do
    let(:original_court_locs) do
      [
        { 'crt_loc_cd' => '1337D', 'crt_loc_desc' => 'RIVENDALE DISTRICT (444 hobbit lane)' },
        { 'crt_loc_cd' => '8675R', 'crt_loc_desc' => 'ROHAN COURT (123 Horse Lord Blvd)' },
        { 'crt_loc_cd' => '1776B', 'crt_loc_desc' => 'MORDER COUNTY (666 Doom rd)' }
      ]
    end

    let(:expected_court_locs) do
      {
        '1337D' => 'RIVENDALE DISTRICT (444 hobbit lane)',
        '8675R' => 'ROHAN COURT (123 Horse Lord Blvd)',
        '1776B' => 'MORDER COUNTY (666 Doom rd)'
      }
    end

    subject { described_class.generate_locations_hash(original_court_locs) }

    it 'transforms the array into a hash' do
      expect(subject).to eq(expected_court_locs)
    end
  end
end
