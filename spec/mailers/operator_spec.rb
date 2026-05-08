require 'spec_helper'

RSpec.describe OperatorMailer, type: :mailer do
  describe 'send_daily_digest_operator_email' do
    it 'should send email digest with location edits' do
      comment_item = { location_name: 'Foo Bar', location_id: 1, machine_name: 'Attack from Mars', comment: 'foo', user_name: 'somebody' }
      added_item   = { location_name: 'Foo Bar', location_id: 1, machine_name: 'Pirates of the Pacific', comment: nil, user_name: 'somebody' }
      removed_item = { location_name: 'Foo Bar', location_id: 1, machine_name: 'Battle of Midway', comment: nil, user_name: 'somebody' }
      email = OperatorMailer.with(email_to: 'foo@bar.com', machine_comments: [ comment_item ], machines_added: [ added_item ], machines_removed: [ removed_item ]).send_daily_digest_operator_email

      assert_emails 1 do
        email.deliver_later
      end

      assert_equal [ 'foo@bar.com' ], email.to
      assert_equal [ 'admin@pinballmap.com' ], email.from
      assert_equal "Pinball Map - Daily digest of edits to your locations - #{Date.today.strftime('%m/%d/%Y')}", email.subject
    end
  end
end
