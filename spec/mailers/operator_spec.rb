require 'spec_helper'

RSpec.describe OperatorMailer, type: :mailer do
  describe 'send_daily_digest_operator_email' do
    it 'should send email digest with location edits' do
      email = OperatorMailer.with(to_email: 'foo@bar.com', machine_comments: [ 'foo' ], machines_added: [ 'Pirates of the Pacific' ], machines_removed: [ 'Battle of Midway' ]).send_daily_digest_operator_email

      assert_emails 1 do
        email.deliver_later
      end

      assert_equal 'foo@bar.com', email.to
      assert_equal [ 'admin@pinballmap.com' ], email.from
      assert_equal "Pinball Map - Daily digest of edits to your locations - #{Date.today.strftime('%m/%d/%Y')}", email.subject
    end
  end
end
