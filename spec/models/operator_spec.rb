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
    before(:each) do
      ActionMailer::Base.perform_deliveries = true
      ActionMailer::Base.deliveries = []
    end
    after(:each) do
      ActionMailer::Base.deliveries.clear
    end
    it 'Skips operators with no email address set' do
      expect(ActionMailer::Base.deliveries.count).to eq(0)
      @no_email_operator.send_recent_comments
    end

    it 'Skips operators with no changes to report' do
      expect(ActionMailer::Base.deliveries.count).to eq(0)
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

      expect do
        @o.send_recent_comments
        email = ActionMailer::Base.deliveries.last
        expect(email.to).to eq(['foo@bar.com'])
        expect(email.from).to eq(['admin@pinballmap.com'])
        expect(email.subject).to eq("Pinball Map - Daily digest of comments on your machines - #{Date.today.strftime('%m/%d/%Y')}")
        expect(email.body).to include('Here are the comments left on your pinball machines yesterday on Pinball Map')
        expect(email.body).to include('Comment: Sassy Comment')
        expect(email.body).to include('Location: Cleo Corner - 303 Southeast 3rd Avenue, Portland, OR, 97214')
        expect(email.body).to include('Comment: Cleo Comment')
        expect(email.body).to include('Location: Cleo Corner - 303 Southeast 3rd Avenue, Portland, OR, 97214')
      end.to change { ActionMailer::Base.deliveries.size }.by(1)
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

      expect do
        @o.send_recent_comments
        email = ActionMailer::Base.deliveries.last
        expect(email.to).to eq(['foo@bar.com'])
        expect(email.from).to eq(['admin@pinballmap.com'])
        expect(email.subject).to eq("Pinball Map - Daily digest of comments on your machines - #{Date.today.strftime('%m/%d/%Y')}")
        expect(email.body).to include('Here are the comments left on your pinball machines yesterday on Pinball Map')
        expect(email.body).to include('Comment: Sassy Comment')
        expect(email.body).to include('Location: Cleo Corner - 303 Southeast 3rd Avenue, Portland, OR, 97214')
        expect(email.body).to include('Comment: Cleo Comment')
        expect(email.body).to include('Location: Cleo Corner - 303 Southeast 3rd Avenue, Portland, OR, 97214')
      end.to change { ActionMailer::Base.deliveries.size }.by(1)

    end
  end
end
