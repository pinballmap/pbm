require 'spec_helper'

describe Operator do
  before(:each) do
    @r = FactoryBot.create(:region, full_name: 'Portland')
    @o = FactoryBot.create(:operator, region: @r, email: 'foo@bar.com')
    @no_changes_operator = FactoryBot.create(:operator, region: @r, email: 'bar@baz.com')
    @no_email_operator = FactoryBot.create(:operator, region: @r)
    @status = FactoryBot.create(:status, status_type: 'operators', updated_at: Time.current - 1.day)
  end

  describe '#before_destroy' do
    it 'should update timestamp in status table' do
      @o.destroy

      expect(@status.reload.updated_at).to be_within(1.second).of Time.current
    end
  end

  describe '#create' do
    it 'should update timestamp in status table' do
      FactoryBot.create(:operator, name: 'Sassy Moves Today')

      expect(@status.reload.updated_at).to be_within(1.second).of Time.current
    end
  end

  describe '#update' do
    it 'should update timestamp in status table' do
      @no_email_operator.update(email: 'foo@bar.com')

      expect(@status.reload.updated_at).to be_within(1.second).of Time.current
    end
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
      l = FactoryBot.create(:location, region: @r, operator: @o, name: 'Cleo Corner')

      m1 = FactoryBot.create(:machine, name: 'Sassy')
      m2 = FactoryBot.create(:machine, name: 'Cleo')
      lmx1 = FactoryBot.create(:location_machine_xref, location: l, machine: m1)
      lmx2 = FactoryBot.create(:location_machine_xref, location: l, machine: m2)

      mc1 = FactoryBot.create(:machine_condition, location_machine_xref: lmx1, comment: 'Sassy Comment', created_at: (Time.now - 1.day).beginning_of_day)
      mc2 = FactoryBot.create(:machine_condition, location_machine_xref: lmx2, comment: 'Cleo Comment', created_at: (Time.now - 1.day).beginning_of_day)
      mc3 = FactoryBot.create(:machine_condition, location_machine_xref: lmx2, comment: 'Old Cleo Comment', created_at: Date.today - 2.days)

      body = <<HERE
Here's a list of comments made on your pinball machines yesterday on Pinball Map. We're sending this in the hope that it will help you identify, and fix, problems. If you don't want to receive these messages, just reply to this message and tell us!

Comment: Sassy Comment
Location: Cleo Corner - 303 Southeast 3rd Avenue, Portland, OR, 97214
Machine: Sassy
Date: #{mc1.updated_at.strftime('%b %d, %Y - %I:%M%p %Z')}

Comment: Cleo Comment
Location: Cleo Corner - 303 Southeast 3rd Avenue, Portland, OR, 97214
Machine: Cleo
Date: #{mc2.updated_at.strftime('%b %d, %Y - %I:%M%p %Z')}
HERE
      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          body: body,
          subject: "Pinball Map - Daily digest of comments on your machines - #{Date.today.strftime('%m/%d/%Y')}",
          to: 'foo@bar.com',
          from: 'Pinball Map <admin@pinballmap.com>'
        )
      end

      @o.send_recent_comments
    end

    it 'Sends emails to regionless operators with recent comments on their machines' do
      l = FactoryBot.create(:location, region: nil, operator: @o, name: 'Cleo Corner')

      m1 = FactoryBot.create(:machine, name: 'Sassy')
      m2 = FactoryBot.create(:machine, name: 'Cleo')
      lmx1 = FactoryBot.create(:location_machine_xref, location: l, machine: m1)
      lmx2 = FactoryBot.create(:location_machine_xref, location: l, machine: m2)

      mc1 = FactoryBot.create(:machine_condition, location_machine_xref: lmx1, comment: 'Sassy Comment', created_at: (Time.now - 1.day).beginning_of_day)
      mc2 = FactoryBot.create(:machine_condition, location_machine_xref: lmx2, comment: 'Cleo Comment', created_at: (Time.now - 1.day).beginning_of_day)
      mc3 = FactoryBot.create(:machine_condition, location_machine_xref: lmx2, comment: 'Old Cleo Comment', created_at: Date.today - 2.days)

      body = <<HERE
Here's a list of comments made on your pinball machines yesterday on Pinball Map. We're sending this in the hope that it will help you identify, and fix, problems. If you don't want to receive these messages, just reply to this message and tell us!

Comment: Sassy Comment
Location: Cleo Corner - 303 Southeast 3rd Avenue, Portland, OR, 97214
Machine: Sassy
Date: #{mc1.updated_at.strftime('%b %d, %Y - %I:%M%p %Z')}

Comment: Cleo Comment
Location: Cleo Corner - 303 Southeast 3rd Avenue, Portland, OR, 97214
Machine: Cleo
Date: #{mc2.updated_at.strftime('%b %d, %Y - %I:%M%p %Z')}
HERE
      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          body: body,
          subject: "Pinball Map - Daily digest of comments on your machines - #{Date.today.strftime('%m/%d/%Y')}",
          to: 'foo@bar.com',
          from: 'Pinball Map <admin@pinballmap.com>'
        )
      end

      @o.send_recent_comments
    end
  end
end
