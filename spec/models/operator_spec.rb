require 'spec_helper'

describe Operator do
  before(:each) do
    @r = FactoryGirl.create(:region, full_name: 'Portland')
    @o = FactoryGirl.create(:operator, region: @r, email: 'foo@bar.com')
    @no_changes_operator = FactoryGirl.create(:operator, region: @r, email: 'bar@baz.com')
    @no_email_operator = FactoryGirl.create(:operator, region: @r)
  end

  describe '#send_recent_comments' do
    it 'Skips operators with no email address set' do
      expect(Pony).to_not receive(:mail)
      @no_email_operator.send_recent_comments
    end

    it 'Skips operators with no changes to report' do
      expect(Pony).to_not receive(:mail)
      @no_changes_operator.send_recent_comments
    end

    it 'Sends emails to operators with recent comments on their machines' do
      l = FactoryGirl.create(:location, region: @r, operator: @o, name: 'Cleo Corner')

      m1 = FactoryGirl.create(:machine, name: 'Sassy')
      m2 = FactoryGirl.create(:machine, name: 'Cleo')
      lmx1 = FactoryGirl.create(:location_machine_xref, location: l, machine: m1)
      lmx2 = FactoryGirl.create(:location_machine_xref, location: l, machine: m2)

      FactoryGirl.create(:machine_condition, location_machine_xref: lmx1, comment: 'Sassy Comment')
      FactoryGirl.create(:machine_condition, location_machine_xref: lmx2, comment: 'Cleo Comment')
      FactoryGirl.create(:machine_condition, location_machine_xref: lmx2, comment: 'Old Cleo Comment', created_at: Date.today - 2.days)

      body = <<HERE
Here's a list of comments made on your pinball machines that were posted today to #{@o.region.full_name}. We're sending this in the hope that it will help you identify, and fix, problems. If you don't want to receive these messages, please contact pinballmap@fastmail.com.

Comment: Sassy Comment
Location: Cleo Corner - 303 Southeast 3rd Avenue, Portland, OR, 97214
Machine: Sassy

Comment: Cleo Comment
Location: Cleo Corner - 303 Southeast 3rd Avenue, Portland, OR, 97214
Machine: Cleo
HERE
      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          body: body,
          subject: "Pinball Map - Daily Digest of comments made on your machines - #{Date.today.strftime('%m/%d/%Y')}",
          to: 'foo@bar.com',
          from: 'admin@pinballmap.com'
        )
      end

      @o.send_recent_comments
    end
  end
end
