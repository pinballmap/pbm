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

        expect(lmx.machine_conditions.first.comment).to eq('baz')

        lmx.machine_conditions.first.destroy
        lmx.reload

        expect(lmx.machine_conditions.size).to eq(2)
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
