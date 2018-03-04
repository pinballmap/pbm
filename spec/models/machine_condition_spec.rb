require 'spec_helper'

describe MachineCondition do
  context 'keep a lot of lmx conditions' do
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
        expect(submission.submission).to eq("User #{user.username} (#{user.email}) commented on #{lmx.machine.name} at #{lmx.location.name}. They said: yep")
        expect(submission.submission_type).to eq(UserSubmission::NEW_CONDITION_TYPE)
      end
    end
  end
end
