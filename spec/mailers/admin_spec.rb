require 'spec_helper'

RSpec.describe AdminMailer, type: :mailer do
  describe 'send_weekly_digest_global' do
    it 'should send an email' do
      email = AdminMailer.with(user: 'foo@bar.com', machines_count: 1, locations_count: 1, machineless_locations: [ 'Sassy House' ], suggested_locations_count: 1, locations_added_count: 1, locations_deleted_count: 1, machine_comments_count: 1, machines_added_count: 1, machines_removed_count: 1, pictures_added_count: 1, pictures_removed_count: 1, contact_messages_count: 1).send_weekly_digest_global

      assert_emails 1 do
        email.deliver_now
      end

      assert_equal [ 'admin@pinballmap.com' ], email.from
      assert_equal [ 'foo@bar.com' ], email.to
      assert_equal "Pinball Map - Weekly admin global digest - #{Date.today.strftime('%m/%d/%Y')}", email.subject
    end
  end
  describe 'send_daily_digest_region' do
    it 'should send a daily region digest email' do
      comment_item  = { location_name: 'Foo Bar', location_id: 1, machine_name: 'Attack from Mars', comment: 'plays great', user_name: 'alice' }
      removal_item  = { location_name: 'Foo Bar', location_id: 1, machine_name: 'Black Knight', user_name: 'bob' }
      picture_item  = { location_name: 'Foo Bar', location_id: 1, user_name: 'carol' }
      email_subject = "Pinball Map - Daily activity digest (Portland) - #{(Date.today - 1.day).strftime('%m/%d/%Y')}"

      email = AdminMailer.with(email_to: 'foo@bar.com', email_subject: email_subject, region_name: 'Portland', machine_comments: [ comment_item ], machine_removals: [ removal_item ], pictures_added: [ picture_item ], machine_comments_count: 1, machine_removals_count: 1, pictures_added_count: 1, machines_added_count: 0, scores_added_count: 0).send_daily_digest_region

      assert_emails 1 do
        email.deliver_later
      end

      assert_equal [ 'foo@bar.com' ], email.to
      assert_equal [ 'admin@pinballmap.com' ], email.from
      assert_equal email_subject, email.subject
    end
  end

  describe 'send_daily_digest_global' do
    it 'should send a daily global digest email' do
      comment_item = { location_name: 'Foo Bar', location_id: 1, machine_name: 'Attack from Mars', comment: 'plays great', user_name: 'alice' }

      email = AdminMailer.with(user: 'foo@bar.com', machine_comments: [ comment_item ], machine_removals: [], pictures_added: [], location_metadata: [], remove_and_readd: [], machine_comments_count: 1, machine_removals_count: 0, pictures_added_count: 0, location_metadata_count: 0, machines_added_count: 0, scores_added_count: 0).send_daily_digest_global

      assert_emails 1 do
        email.deliver_later
      end

      assert_equal [ 'foo@bar.com' ], email.to
      assert_equal [ 'admin@pinballmap.com' ], email.from
      assert_equal "Pinball Map - Daily global activity digest - #{(Date.today - 1.day).strftime('%m/%d/%Y')}", email.subject
    end
  end

  describe 'new location submitted' do
    it 'should send email on new location submission' do
      email = AdminMailer.with(to_users: [ 'foo@bar.com' ], region_id: nil, location_name: 'name', subject: 'Pinball Map - New location - name', location_machine: 'machine').send_new_location_notification

      assert_emails 1 do
        email.deliver_later
      end

      assert_equal email.to, [ 'foo@bar.com' ]
      assert_equal email.from, [ 'admin@pinballmap.com' ]
      assert_equal email.subject, 'Pinball Map - New location - name'
    end
  end
  describe 'send admin notification' do
    it 'should send email on new location submission' do
      email = AdminMailer.with(to_users: [ 'foo@bar.com' ], email: 'email', name: 'name', message: 'message', subject: 'Pinball Map - Message from name').send_admin_notification

      assert_emails 1 do
        email.deliver_later
      end

      assert_equal email.to, [ 'foo@bar.com' ]
      assert_equal email.reply_to, [ 'email' ]
      assert_equal email.from, [ 'admin@pinballmap.com' ]
      assert_equal email.subject, 'Pinball Map - Message from name'
    end
  end
end
