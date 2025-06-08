require 'spec_helper'

describe MachineScoreXref do
  context 'manipulate score data' do
    before(:each) do
      @lmx = FactoryBot.create(:location_machine_xref, location: FactoryBot.create(:location), machine: FactoryBot.create(:machine))
    end

    describe '#username' do
      it 'should display blank when there is no user associated with the score' do
        userless_score = FactoryBot.create(:machine_score_xref, location_machine_xref: @lmx, user: nil)
        expect(userless_score.username).to eq('')

        user_score = FactoryBot.create(:machine_score_xref, location_machine_xref: @lmx, user: FactoryBot.create(:user, username: 'cibw'))
        expect(user_score.username).to eq('cibw')
      end
    end

    describe '#create_user_submission' do
      it 'creates a user submission' do
        user = FactoryBot.create(:user, username: 'cibw', email: 'yeah@ok.com')
        msx = FactoryBot.create(:machine_score_xref, location_machine_xref: @lmx, user: user, score: 100)

        msx.create_user_submission

        submission = UserSubmission.second

        expect(submission.location).to eq(@lmx.location)
        expect(submission.machine).to eq(@lmx.machine)
        expect(submission.user).to eq(user)
        expect(submission.submission_type).to eq(UserSubmission::NEW_SCORE_TYPE)
        expect(submission.submission).to eq('cibw added a high score of 100 on Test Machine Name at Test Location Name in Portland')
      end
    end
  end
end
