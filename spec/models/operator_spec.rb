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
      expect { @no_email_operator.send_recent_comments }.to_not have_enqueued_job
    end

    it 'Skips operators with no changes to report' do
      expect { @no_changes_operator.send_recent_comments }.to_not have_enqueued_job
    end

    it 'Sends emails to operators with recent comments on their machines' do
      l = FactoryBot.create(:location, region: @r, operator: @o, name: 'Cleo Corner')

      m1 = FactoryBot.create(:machine, name: 'Sassy')
      m2 = FactoryBot.create(:machine, name: 'Cleo')
      lmx1 = FactoryBot.create(:location_machine_xref, location: l, machine: m1)
      lmx2 = FactoryBot.create(:location_machine_xref, location: l, machine: m2)

      mc1 = FactoryBot.create(:machine_condition, location_machine_xref: lmx1, comment: 'Sassy Comment', created_at: (Time.now - 1.day).beginning_of_day, updated_at: (Time.now - 1.day).beginning_of_day)
      mc2 = FactoryBot.create(:machine_condition, location_machine_xref: lmx2, comment: 'Cleo Comment', created_at: (Time.now - 1.day).beginning_of_day, updated_at: (Time.now - 1.day).beginning_of_day)
      FactoryBot.create(:machine_condition, location_machine_xref: lmx2, comment: 'Old Cleo Comment', created_at: Date.today - 2.days)

      expect { @o.send_recent_comments }.to have_enqueued_job(ActionMailer::MailDeliveryJob).with('OperatorMailer', 'send_recent_comments', 'deliver_now', { params: { email: 'foo@bar.com', heading: "Here are the comments left on your pinball machines yesterday on Pinball Map. We hope this helps you identify and fix problems. You opted in to receive these, but if you don't want them anymore reply to this message and tell us! Also, see our FAQ: https://pinballmap.com/faq#operators", comments: ["Comment: Sassy Comment\nLocation: Cleo Corner - 303 Southeast 3rd Avenue, Portland, OR, 97214\nMachine: Sassy\nDate: #{mc1.updated_at.strftime('%b %d, %Y - %I:%M%p %Z')}", "Comment: Cleo Comment\nLocation: Cleo Corner - 303 Southeast 3rd Avenue, Portland, OR, 97214\nMachine: Cleo\nDate: #{mc2.updated_at.strftime('%b %d, %Y - %I:%M%p %Z')}"] }, args: [] })
    end

    it 'Sends emails to regionless operators with recent comments on their machines' do
      l = FactoryBot.create(:location, region: nil, operator: @o, name: 'Cleo Corner')

      m1 = FactoryBot.create(:machine, name: 'Sassy')
      m2 = FactoryBot.create(:machine, name: 'Cleo')
      lmx1 = FactoryBot.create(:location_machine_xref, location: l, machine: m1)
      lmx2 = FactoryBot.create(:location_machine_xref, location: l, machine: m2)

      mc1 = FactoryBot.create(:machine_condition, location_machine_xref: lmx1, comment: 'Sassy Comment', created_at: (Time.now - 1.day).beginning_of_day)
      mc2 = FactoryBot.create(:machine_condition, location_machine_xref: lmx2, comment: 'Cleo Comment', created_at: (Time.now - 1.day).beginning_of_day)
      FactoryBot.create(:machine_condition, location_machine_xref: lmx2, comment: 'Old Cleo Comment', created_at: Date.today - 2.days)

      expect { @o.send_recent_comments }.to have_enqueued_job(ActionMailer::MailDeliveryJob).with('OperatorMailer', 'send_recent_comments', 'deliver_now', { params: { email: 'foo@bar.com', heading: "Here are the comments left on your pinball machines yesterday on Pinball Map. We hope this helps you identify and fix problems. You opted in to receive these, but if you don't want them anymore reply to this message and tell us! Also, see our FAQ: https://pinballmap.com/faq#operators", comments: ["Comment: Sassy Comment\nLocation: Cleo Corner - 303 Southeast 3rd Avenue, Portland, OR, 97214\nMachine: Sassy\nDate: #{mc1.updated_at.strftime('%b %d, %Y - %I:%M%p %Z')}", "Comment: Cleo Comment\nLocation: Cleo Corner - 303 Southeast 3rd Avenue, Portland, OR, 97214\nMachine: Cleo\nDate: #{mc2.updated_at.strftime('%b %d, %Y - %I:%M%p %Z')}"] }, args: [] })
    end
  end
end
