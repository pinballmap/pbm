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

      assert_equal 1, MachineCondition.all.count
      assert_equal 'regionless condish', MachineCondition.first.comment
    end

    it 'should update the condition of the lmx and timestamp it' do
      freeze_time do
        @lmx.update_condition('foo', user_id: @u.id)

        assert_equal 'foo', @lmx.machine_conditions.first.comment
        assert_equal Time.current, @lmx.updated_at
      end

      @lmx.update_condition('bar', remote_ip: '0.0.0.0', user_agent: 'cleOS', user_id: @u.id)
    end

    it 'should do nothing if your condition is the same as the previous condition' do
      @lmx.update_condition('baz', user_id: @u.id)
      @lmx.update_condition('baz', user_id: @u.id)

      assert_equal 1, MachineCondition.all.count
    end

    it 'should create MachineConditions' do
      @lmx.update_condition('foo')

      assert_equal 1, MachineCondition.all.count
      assert_equal 'foo', MachineCondition.first.comment
    end

    it 'should tag update with a user when given' do
      @lmx.update_condition('foo', user_id: FactoryBot.create(:user, id: 10, username: 'foo').id)

      assert_equal 10, @lmx.user_id
      assert_equal 'foo', @lmx.last_updated_by_username
    end
  end

  describe '#destroy' do
    it 'works with regionless locations' do
      regionless_location = FactoryBot.create(:location, name: 'Regionless Location', region: nil)
      regionless_lmx = FactoryBot.create(:location_machine_xref, location: regionless_location, machine: @m)

      user = User.find(1)
      regionless_lmx.destroy(user_id: user.id)

      refute_includes LocationMachineXref.all, regionless_lmx
      submission = UserSubmission.last

      assert_equal nil, submission.region
      assert_equal user, submission.user
      assert_equal regionless_lmx.location, submission.location
      assert_equal regionless_lmx.machine, submission.machine
      assert_equal "#{@m.name} was removed from #{regionless_location.name} in #{regionless_location.city} by #{user.name}", submission.submission
      assert_equal UserSubmission::REMOVE_MACHINE_TYPE, submission.submission_type
    end

    it 'should remove the lmx' do
      @lmx.destroy(remote_ip: '0.0.0.0', user_agent: 'cleOS')

      assert_equal [], LocationMachineXref.all
    end

    it 'auto-creates a user submission' do
      user = User.find(1)
      @lmx.destroy(user_id: user.id)

      submission = UserSubmission.last

      assert_equal @l.region, submission.region
      assert_equal user, submission.user
      assert_equal @lmx.location, submission.location
      assert_equal @lmx.machine, submission.machine
      assert_equal "#{@m.name} was removed from #{@l.name} in #{@l.city} by #{user.name}", submission.submission
      assert_equal UserSubmission::REMOVE_MACHINE_TYPE, submission.submission_type
    end
  end

  describe '#last_updated_by_username' do
    it 'should return the most recent comments username' do
      lmx = FactoryBot.create(:location_machine_xref)

      assert_equal '', lmx.last_updated_by_username

      lmx = FactoryBot.create(:location_machine_xref, user: FactoryBot.create(:user, id: 666, username: 'foo'))

      assert_equal 'foo', lmx.last_updated_by_username
    end
  end

  describe '#create' do
    it 'auto-creates a user submission' do
      user = FactoryBot.create(:user, id: 777)

      FactoryBot.create(:location_machine_xref, location: @l, machine: @m, user: user)

      submission = UserSubmission.last

      assert_equal @l.region, submission.region
      assert_equal user, submission.user
      assert_equal @l, submission.location
      assert_equal @m, submission.machine
      assert_equal "#{@m.name} was added to #{@l.name} in #{@l.city} by #{user.name}", submission.submission
      assert_equal UserSubmission::NEW_LMX_TYPE, submission.submission_type
    end
  end

  describe '#last_updated_by_username' do
    it 'should return the most recent comments username' do
      lmx = FactoryBot.create(:location_machine_xref)

      assert_equal '', lmx.last_updated_by_username

      lmx = FactoryBot.create(:location_machine_xref, user: FactoryBot.create(:user, id: 666, username: 'foo'))

      assert_equal 'foo', lmx.last_updated_by_username
    end
  end
end
