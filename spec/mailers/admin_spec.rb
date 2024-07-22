require 'spec_helper'

RSpec.describe AdminMailer, type: :mailer do
  describe 'weekly_admin_digest_regionless' do
    it 'should send an email' do
      email = AdminMailer.with(user: 'foo@bar.com', machines_count: 1, locations_count: 1, machineless_locations: ['Sassy House'], suggested_locations: ['Lounge Bar'], suggested_locations_count: 1, locations_added_count: 1, locations_deleted_count: 1, machine_comments_count: 1, machines_added_count: 1, machines_removed_count: 1).weekly_admin_digest_regionless

      assert_emails 1 do
        email.deliver_now
      end

      assert_equal ['admin@pinballmap.com'], email.from
      assert_equal ['foo@bar.com'], email.to
      assert_equal "Pinball Map - Weekly admin REGIONLESS digest - #{Date.today.strftime('%m/%d/%Y')}", email.subject
    end
  end
  describe 'new location submitted' do
    it 'should send email on new location submission' do
      email = AdminMailer.with(to_users: ['foo@bar.com'], region_id: nil, location_name: 'name', subject: 'Pinball Map - New location suggested', location_machine: 'machine').send_new_location_notification

      assert_emails 1 do
        email.deliver_later
      end

      assert_equal email.to, ['foo@bar.com']
      assert_equal email.from, ['admin@pinballmap.com']
      assert_equal email.subject, 'Pinball Map - New location suggested'
    end
  end
  describe 'send admin notification' do
    it 'should send email on new location submission' do
      email = AdminMailer.with(to_users: ['foo@bar.com'], email: 'email', name: 'name', message: 'message', subject: 'Pinball Map - Message').send_admin_notification

      assert_emails 1 do
        email.deliver_later
      end

      assert_equal email.to, ['foo@bar.com']
      assert_equal email.from, ['admin@pinballmap.com']
      assert_equal email.subject, 'Pinball Map - Message'
    end
  end
end
