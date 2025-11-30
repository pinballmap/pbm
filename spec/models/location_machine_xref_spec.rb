require 'spec_helper'

describe LocationMachineXref do
  before(:each) do
    @r = FactoryBot.create(:region, name: 'Portland', should_email_machine_removal: 0)
    @u = FactoryBot.create(:user, id: 1, region: @r, username: 'ssw', email: 'foo@bar.com')
    @l = FactoryBot.create(:location, region: @r, name: 'Cool Bar')
    @m = FactoryBot.create(:machine, name: 'Sassy')
    @lmx = FactoryBot.create(:location_machine_xref, location: @l, machine: @m)
  end

  describe '#update_condition' do
    it 'should work with regionless locations' do
      regionless_location = FactoryBot.create(:location, region: nil, name: 'REGIONLESS')
      regionless_lmx = FactoryBot.create(:location_machine_xref, location: regionless_location, machine: @m)

      regionless_lmx.update_condition('regionless condish', user_id: @u.id)

      expect(MachineCondition.all.count).to eq(1)
      expect(MachineCondition.first.comment).to eq('regionless condish')
    end

    it 'should update the condition of the lmx and timestamp it' do
      freeze_time do
        @lmx.update_condition('foo', user_id: @u.id)

        expect(@lmx.machine_conditions.first.comment).to eq('foo')
        expect(@lmx.updated_at).to eq(Time.current)
      end

      @lmx.update_condition('bar', remote_ip: '0.0.0.0', user_agent: 'cleOS', user_id: @u.id)
    end

    it 'should do nothing if your condition is the same as the previous condition' do
      @lmx.update_condition('baz', user_id: @u.id)
      @lmx.update_condition('baz', user_id: @u.id)

      expect(MachineCondition.all.count).to eq(1)
    end

    it 'should create MachineConditions' do
      @lmx.update_condition('foo')

      expect(MachineCondition.all.count).to eq(1)
      expect(MachineCondition.first.comment).to eq('foo')
    end

    it 'should tag update with a user when given' do
      @lmx.update_condition('foo', user_id: FactoryBot.create(:user, id: 10, username: 'foo').id)

      expect(@lmx.user_id).to eq(10)
      expect(@lmx.last_updated_by_username).to eq('foo')
    end
  end

  describe '#destroy' do
    it 'should not destroy the lmx without force: true' do
      location = FactoryBot.create(:location, name: 'Regionless Location', region: nil)
      user = User.find(1)
      lmx = FactoryBot.create(:location_machine_xref, location: location, machine: @m, user_id: user.id)

      lmx.destroy({ user_id: user.id })

      expect(LocationMachineXref.all.size).to eq(2)
    end

    it 'should destroy the lmx when force: true is included' do
      location = FactoryBot.create(:location, name: 'Regionless Location', region: nil)
      user = User.find(1)
      lmx = FactoryBot.create(:location_machine_xref, location: location, machine: @m, user_id: user.id)

      lmx.destroy({ user_id: user.id }, force: true)

      expect(LocationMachineXref.all.size).to eq(1)
    end

    it 'works with regionless locations' do
      regionless_location = FactoryBot.create(:location, name: 'Regionless Location', region: nil)
      user = User.find(1)
      regionless_lmx = FactoryBot.create(:location_machine_xref, location: regionless_location, machine: @m, user_id: user.id)

      regionless_lmx.destroy({ user_id: user.id }, force: true)

      expect(LocationMachineXref.all).to_not include(regionless_lmx)
      expect(LocationMachineXref.all).to_not include(regionless_lmx)
      submission = UserSubmission.last

      expect(submission.region).to eq(nil)
      expect(submission.user).to eq(user)
      expect(submission.location).to eq(regionless_lmx.location)
      expect(submission.machine).to eq(regionless_lmx.machine)
      expect(submission.submission).to eq("#{@m.name} was removed from #{regionless_location.name} in #{regionless_location.city} by #{user.name}")
      expect(submission.submission_type).to eq(UserSubmission::REMOVE_MACHINE_TYPE)
    end
  end

  describe '#last_updated_by_username' do
    it 'should return the most recent comments username' do
      lmx = FactoryBot.create(:location_machine_xref)

      expect(lmx.last_updated_by_username).to eq('')

      lmx = FactoryBot.create(:location_machine_xref, user: FactoryBot.create(:user, id: 666, username: 'foo'))

      expect(lmx.last_updated_by_username).to eq('foo')
    end
  end

  describe '#create' do
    it 'auto-creates a user submission' do
      user = FactoryBot.create(:user, id: 777)

      FactoryBot.create(:location_machine_xref, location: @l, machine: @m, user: user)

      submission = UserSubmission.last

      expect(submission.region).to eq(@l.region)
      expect(submission.user).to eq(user)
      expect(submission.location).to eq(@l)
      expect(submission.machine).to eq(@m)
      expect(submission.submission).to eq("#{@m.name} was added to #{@l.name} in #{@l.city} by #{user.name}")
      expect(submission.submission_type).to eq(UserSubmission::NEW_LMX_TYPE)
    end
  end

  describe '#last_updated_by_username' do
    it 'should return the most recent comments username' do
      lmx = FactoryBot.create(:location_machine_xref)

      expect(lmx.last_updated_by_username).to eq('')

      lmx = FactoryBot.create(:location_machine_xref, user: FactoryBot.create(:user, id: 666, username: 'foo'))

      expect(lmx.last_updated_by_username).to eq('foo')
    end
  end
end
