require 'spec_helper'

describe MachineScoreXref do
  context 'manipulate score data' do
    before(:each) do
      @lmx = FactoryBot.create(:location_machine_xref, location: FactoryBot.create(:location), machine: FactoryBot.create(:machine))
    end

    describe '#username' do
      it 'should display blank when there is no user associated with the score' do
        userless_score = FactoryBot.create(:machine_score_xref, location_machine_xref: @lmx, user: nil)
        assert_equal '', userless_score.username

        user_score = FactoryBot.create(:machine_score_xref, location_machine_xref: @lmx, user: FactoryBot.create(:user, username: 'cibw'))
        assert_equal 'cibw', user_score.username
      end
    end

    describe '#create_user_submission' do
      it 'creates a user submission' do
        user = FactoryBot.create(:user, username: 'cibw', email: 'yeah@ok.com')
        msx = FactoryBot.create(:machine_score_xref, location_machine_xref: @lmx, user: user, score: 100)

        msx.create_user_submission

        submission = UserSubmission.second

        assert_equal @lmx.location, submission.location
        assert_equal @lmx.machine, submission.machine
        assert_equal user, submission.user
        assert_equal UserSubmission::NEW_SCORE_TYPE, submission.submission_type
        assert_equal 'cibw added a high score of 100 on Test Machine Name at Test Location Name in Portland', submission.submission
      end
    end
  end
end
