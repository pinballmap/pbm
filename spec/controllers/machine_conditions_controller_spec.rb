require 'spec_helper'

describe MachineConditionsController, type: :controller do
  before(:each) do
    FactoryBot.create(:user, email: 'foo@bar.com', region: @region)
    @region = FactoryBot.create(:region, name: 'portland')
    @location = FactoryBot.create(:location, id: 1)
    @machine = FactoryBot.create(:machine)
    @user = FactoryBot.create(:user, username: 'ssw', email: 'ssw@yeah.com')
    @lmx = FactoryBot.create(:location_machine_xref, location: @location, machine: @machine)
    @lmx.update_condition('foo', { user_id: @user.id })
  end

  describe 'update' do
    it 'should update MachineConditions that you own' do
      login(@user)
      mc = @lmx.machine_conditions.first

      post 'update', params: { comment: 'Civil War was a bad movie', id: mc.id }

      mc.reload

      expect(mc.comment).to eq('Civil War was a bad movie')

      submission = UserSubmission.last

      expect(submission.location).to eq(@lmx.location)
      expect(submission.machine).to eq(@lmx.machine)
      expect(submission.user).to eq(@user)
      expect(submission.submission_type).to eq(UserSubmission::NEW_CONDITION_TYPE)
      expect(submission.submission).to eq('ssw commented on Test Machine Name at Test Location Name in Portland. They said: Civil War was a bad movie')
      expect(submission.comment).to eq('Civil War was a bad movie')
    end

    it 'should not update MachineConditions that you do not own' do
      mc = @lmx.machine_conditions.first

      bad_user = FactoryBot.create(:user, username: 'acidburn', email: 'crash@override.com')
      login(bad_user)

      post 'update', params: { comment: 'Civil War was a bad movie', id: mc.id }

      mc.reload

      expect(mc.comment).to eq('foo')
    end
  end

  describe 'destroy' do
    it 'should destroy MachineConditions that you own' do
      login(@user)
      mc = @lmx.machine_conditions.first

      post 'destroy', params: { id: mc.id }

      expect(MachineCondition.count).to eq(0)
      expect(UserSubmission.last.deleted_at).to_not eq(nil)
    end

    it 'should not destroy MachineConditions that you do not own' do
      mc = @lmx.machine_conditions.first

      bad_user = FactoryBot.create(:user, username: 'acidburn', email: 'crash@override.com')
      login(bad_user)

      post 'destroy', params: { id: mc.id }

      mc.reload

      expect(mc.comment).to eq('foo')
    end
  end
end
