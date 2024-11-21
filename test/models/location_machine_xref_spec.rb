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

      expect(MachineCondition.all.count).must_equal 1
      expect(MachineCondition.first.comment).must_equal 'regionless condish'
    end

    it 'should update the condition of the lmx and timestamp it' do
      freeze_time do
        @lmx.update_condition('foo', user_id: @u.id)

        expect(@lmx.machine_conditions.first.comment).must_equal 'foo'
        expect(@lmx.updated_at).must_equal Time.current
      end

      @lmx.update_condition('bar', remote_ip: '0.0.0.0', user_agent: 'cleOS', user_id: @u.id)
    end

    it 'should do nothing if your condition is the same as the previous condition' do
      @lmx.update_condition('baz', user_id: @u.id)
      @lmx.update_condition('baz', user_id: @u.id)

      expect(MachineCondition.all.count).must_equal 1
    end

    it 'should create MachineConditions' do
      @lmx.update_condition('foo')

      expect(MachineCondition.all.count).must_equal 1
      expect(MachineCondition.first.comment).must_equal 'foo'
    end

    it 'should tag update with a user when given' do
      @lmx.update_condition('foo', user_id: FactoryBot.create(:user, id: 10, username: 'foo').id)

      expect(@lmx.user_id).must_equal 10
      expect(@lmx.last_updated_by_username).must_equal 'foo'
    end
  end

  describe '#destroy' do
    it 'works with regionless locations' do
      regionless_location = FactoryBot.create(:location, name: 'Regionless Location', region: nil)
      regionless_lmx = FactoryBot.create(:location_machine_xref, location: regionless_location, machine: @m)

      user = User.find(1)
      regionless_lmx.destroy(user_id: user.id)

      expect(LocationMachineXref.all).wont_include regionless_lmx
      submission = UserSubmission.last

      expect(submission.region).must_equal nil
      expect(submission.user).must_equal user
      expect(submission.location).must_equal regionless_lmx.location
      expect(submission.machine).must_equal regionless_lmx.machine
      expect(submission.submission).must_equal "#{@m.name} was removed from #{regionless_location.name} in #{regionless_location.city} by #{user.name}"
      expect(submission.submission_type).must_equal UserSubmission::REMOVE_MACHINE_TYPE
    end

    it 'should remove the lmx' do
      @lmx.destroy(remote_ip: '0.0.0.0', user_agent: 'cleOS')

      expect(LocationMachineXref.all).must_equal []
    end

    it 'auto-creates a user submission' do
      user = User.find(1)
      @lmx.destroy(user_id: user.id)

      submission = UserSubmission.last

      expect(submission.region).must_equal @l.region
      expect(submission.user).must_equal user
      expect(submission.location).must_equal @lmx.location
      expect(submission.machine).must_equal @lmx.machine
      expect(submission.submission).must_equal "#{@m.name} was removed from #{@l.name} in #{@l.city} by #{user.name}"
      expect(submission.submission_type).must_equal UserSubmission::REMOVE_MACHINE_TYPE
    end
  end

  describe '#last_updated_by_username' do
    it 'should return the most recent comments username' do
      lmx = FactoryBot.create(:location_machine_xref)

      expect(lmx.last_updated_by_username).must_equal ''

      lmx = FactoryBot.create(:location_machine_xref, user: FactoryBot.create(:user, id: 666, username: 'foo'))

      expect(lmx.last_updated_by_username).must_equal 'foo'
    end
  end

  describe '#create' do
    it 'auto-creates a user submission' do
      user = FactoryBot.create(:user, id: 777)

      FactoryBot.create(:location_machine_xref, location: @l, machine: @m, user: user)

      submission = UserSubmission.last

      expect(submission.region).must_equal @l.region
      expect(submission.user).must_equal user
      expect(submission.location).must_equal @l
      expect(submission.machine).must_equal @m
      expect(submission.submission).must_equal "#{@m.name} was added to #{@l.name} in #{@l.city} by #{user.name}"
      expect(submission.submission_type).must_equal UserSubmission::NEW_LMX_TYPE
    end
  end

  describe '#last_updated_by_username' do
    it 'should return the most recent comments username' do
      lmx = FactoryBot.create(:location_machine_xref)

      expect(lmx.last_updated_by_username).must_equal ''

      lmx = FactoryBot.create(:location_machine_xref, user: FactoryBot.create(:user, id: 666, username: 'foo'))

      expect(lmx.last_updated_by_username).must_equal 'foo'
    end
  end
end
