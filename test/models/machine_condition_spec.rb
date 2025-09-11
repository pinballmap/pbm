require 'spec_helper'

describe MachineCondition do
  context 'keep a lot of lmx conditions' do
    describe '#update' do
      it 'correctly updates lmx condition metadata: updates lmx if you update the most recent of many conditions' do
        location = FactoryBot.create(:location, region: FactoryBot.create(:region))
        machine = FactoryBot.create(:machine)
        lmx = FactoryBot.create(:location_machine_xref, location: location, machine: machine)

        lmx.update_condition('foo')
        lmx.update_condition('bar')
        lmx.update_condition('baz')
        mc = lmx.machine_conditions.first

        assert_equal mc.updated_at, mc.created_at
        assert_equal 'baz', mc.comment

        mc.update({ comment: 'dang' })
        lmx.reload

        refute_equal mc.updated_at, mc.created_at
        assert_equal 'dang', mc.comment
      end
    end

    describe '#destroy' do
      it 'correctly updates lmx condition metadata: updates lmx if you delete the most recent of many conditions' do
        location = FactoryBot.create(:location, region: FactoryBot.create(:region))
        machine = FactoryBot.create(:machine)
        lmx = FactoryBot.create(:location_machine_xref, location: location, machine: machine)

        lmx.update_condition('foo')
        lmx.update_condition('bar')
        lmx.update_condition('baz')
        lmx.reload

        assert_equal 'baz', lmx.machine_conditions.first.comment

        lmx.machine_conditions.first.destroy
        lmx.reload

        assert_equal 2, lmx.machine_conditions.size
      end
    end

    describe '#create' do
      it 'auto-creates a user submission' do
        location = FactoryBot.create(:location, region: FactoryBot.create(:region))
        machine = FactoryBot.create(:machine)
        user = FactoryBot.create(:user)
        lmx = FactoryBot.create(:location_machine_xref, location: location, machine: machine)
        FactoryBot.create(:machine_condition, user: user, comment: 'yep', location_machine_xref: lmx)

        submission = UserSubmission.second

        assert_equal lmx.location.region, submission.region
        assert_equal user, submission.user
        assert_equal lmx.location, submission.location
        assert_equal lmx.machine, submission.machine
        assert_equal "#{user.username} commented on #{lmx.machine.name} at #{lmx.location.name} in #{lmx.location.city}. They said: yep", submission.submission
        assert_equal UserSubmission::NEW_CONDITION_TYPE, submission.submission_type
      end
    end
  end
end
