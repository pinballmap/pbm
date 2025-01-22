require 'spec_helper'

RSpec.describe OperatorMailer, type: :mailer do
  describe 'send_recent_comments' do
    it 'should send email digest with machine comments' do
      email = OperatorMailer.with(email: [ 'foo@bar.com' ], location_id: 'Sassy Mo', comments: [ 'foo' ]).send_recent_comments

      assert_emails 1 do
        email.deliver_later
      end

      assert_equal email.to, [ 'foo@bar.com' ]
      assert_equal [ 'admin@pinballmap.com' ], email.from
      assert_equal email.subject, "Pinball Map - Daily digest of comments on your machines - #{Date.today.strftime('%m/%d/%Y')}"
    end
  end
end
