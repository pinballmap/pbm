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

  describe 'generate_operator_daily_digest' do
    it 'Skips operators with no email address set' do
      expect { @no_email_operator.generate_operator_daily_digest }.to_not have_enqueued_job
    end

    it 'Skips operators with no changes to report' do
      expect { @no_changes_operator.generate_operator_daily_digest }.to_not have_enqueued_job
    end

    it 'Sends emails to operators with recent comments on their machines' do
      @l = FactoryBot.create(:location, region: @r, operator: @o, name: 'Cleo Corner')

      FactoryBot.create(:user_submission, created_at: (Time.now - 1.day), location: @l, submission: 'foo', submission_type: UserSubmission::NEW_LMX_TYPE)

      FactoryBot.create(:user_submission, created_at: (Time.now - 1.day), location: @l, submission: 'crap', submission_type: UserSubmission::NEW_CONDITION_TYPE, deleted_at: (Time.now - 1.day))

      FactoryBot.create(:user_submission, created_at: (Time.now - 1.day), location: @l, submission: 'bar', submission_type: UserSubmission::REMOVE_MACHINE_TYPE)

      FactoryBot.create(:user_submission, created_at: (Time.now - 1.day), location: @l, submission: 'baz', submission_type: UserSubmission::NEW_CONDITION_TYPE)

      FactoryBot.create(:user_submission, created_at: (Time.now - 3.day), location: @l, submission: 'bong', submission_type: UserSubmission::NEW_CONDITION_TYPE)

      expect(@o.generate_operator_daily_digest[:machine_comments]).to eq(%w[baz])
    end
  end
end
