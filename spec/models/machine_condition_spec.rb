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

        expect(mc.created_at).to eq(mc.updated_at)
        expect(mc.comment).to eq('baz')

        mc.update({ comment: 'dang' })
        lmx.reload

        expect(mc.created_at).to_not eq(mc.updated_at)
        expect(mc.comment).to eq('dang')
        expect(lmx.condition).to eq('dang')
      end

      it 'correctly updates lmx condition metadata: leaves lmx alone if you did not update the most recent condition' do
        location = FactoryBot.create(:location, region: FactoryBot.create(:region))
        machine = FactoryBot.create(:machine)
        lmx = FactoryBot.create(:location_machine_xref, location: location, machine: machine)

        lmx.update_condition('foo')
        lmx.update_condition('bar')
        lmx.update_condition('baz')
        mc = lmx.machine_conditions.third

        expect(lmx.condition).to eq('baz')

        mc.update({ comment: 'WHOOPS' })

        expect(mc.created_at).to_not eq(mc.updated_at)
        expect(mc.comment).to eq('WHOOPS')
        expect(lmx.condition).to eq('baz')
      end

      it 'does nothing if the new condition is blank or the same condition that was there before' do
        location = FactoryBot.create(:location, region: FactoryBot.create(:region))
        machine = FactoryBot.create(:machine)
        lmx = FactoryBot.create(:location_machine_xref, location: location, machine: machine)
        lmx.update_condition('foo')
        mc = lmx.machine_conditions.first

        mc.update({ comment: '' })
        mc.reload

        expect(mc.comment).to eq('foo')
        expect(mc.created_at).to eq(mc.updated_at)

        mc.update({ comment: 'foo' })
        mc.reload

        expect(mc.comment).to eq('foo')
        expect(mc.created_at).to eq(mc.updated_at)
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

        expect(lmx.condition).to eq('baz')

        lmx.machine_conditions.first.destroy
        lmx.reload

        expect(lmx.machine_conditions.size).to eq(2)
        expect(lmx.condition).to eq('bar')
      end

      it 'correctly updates lmx condition metadata: leaves lmx alone if you did not delete the most recent condition' do
        location = FactoryBot.create(:location, region: FactoryBot.create(:region))
        machine = FactoryBot.create(:machine)
        lmx = FactoryBot.create(:location_machine_xref, location: location, machine: machine)

        lmx.update_condition('foo')
        lmx.update_condition('bar')
        lmx.update_condition('baz')
        lmx.reload

        expect(lmx.condition).to eq('baz')
        expect(lmx.machine_conditions.third.comment).to eq('foo')

        lmx.machine_conditions.third.destroy
        lmx.reload

        expect(lmx.machine_conditions.size).to eq(2)
        expect(lmx.condition).to eq('baz')
      end

      it 'correctly updates lmx condition metadata: blanks out lmx condition info if you delete the only comment' do
        location = FactoryBot.create(:location, region: FactoryBot.create(:region))
        machine = FactoryBot.create(:machine)
        lmx = FactoryBot.create(:location_machine_xref, location: location, machine: machine)

        lmx.update_condition('foo')
        lmx.reload

        expect(lmx.condition).to eq('foo')
        expect(lmx.machine_conditions.size).to eq(1)

        lmx.machine_conditions.first.destroy
        lmx.reload

        expect(lmx.condition).to be(nil)
        expect(lmx.condition_date).to be(nil)
        expect(lmx.machine_conditions.size).to eq(0)
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

        expect(submission.region).to eq(lmx.location.region)
        expect(submission.user).to eq(user)
        expect(submission.location).to eq(lmx.location)
        expect(submission.machine).to eq(lmx.machine)
        expect(submission.submission).to eq("#{user.username} commented on #{lmx.machine.name} at #{lmx.location.name} in #{lmx.location.city}. They said: yep")
        expect(submission.submission_type).to eq(UserSubmission::NEW_CONDITION_TYPE)
      end
    end
  end
end
