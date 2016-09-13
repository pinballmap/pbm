require 'spec_helper'

describe MachineScoreXref do
  context 'manipulate score data' do
    before(:each) do
      @lmx = FactoryGirl.create(:location_machine_xref, location: FactoryGirl.create(:location), machine: FactoryGirl.create(:machine))
    end

    describe '#username' do
      it 'should display blank when there is no user associated with the score' do
        userless_score = FactoryGirl.create(:machine_score_xref, location_machine_xref: @lmx, user: nil)
        expect(userless_score.username).to eq('')

        user_score = FactoryGirl.create(:machine_score_xref, location_machine_xref: @lmx, user: FactoryGirl.create(:user, username: 'cibw'))
        expect(user_score.username).to eq('cibw')
      end
    end

    describe '#create_user_submission' do
      it 'creates a user submission' do
        user = FactoryGirl.create(:user, username: 'cibw', email: 'yeah@ok.com')
        msx = FactoryGirl.create(:machine_score_xref, location_machine_xref: @lmx, user: user)

        msx.create_user_submission

        submission = UserSubmission.second

        expect(submission.location).to eq(@lmx.location)
        expect(submission.machine).to eq(@lmx.machine)
        expect(submission.user).to eq(user)
        expect(submission.submission_type).to eq(UserSubmission::NEW_SCORE_TYPE)
        expect(submission.submission).to eq('User cibw (yeah@ok.com) added a score for Test Machine Name to Test Location Name')
      end
    end
  end
end
