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

    describe '#update' do
      it 'correctly updates high score metadata: updates lmx if you update the most recent of many high scores' do
        FactoryBot.create(:machine_score_xref, location_machine_xref: @lmx, score: 100)
        FactoryBot.create(:machine_score_xref, location_machine_xref: @lmx, score: 200)
        FactoryBot.create(:machine_score_xref, location_machine_xref: @lmx, score: 300)

        hc = @lmx.machine_score_xrefs.first

        expect(hc.created_at).to eq(hc.updated_at)
        expect(hc.score).to eq(300)

        hc.update({ score: 400 })
        @lmx.reload

        expect(hc.created_at).to_not eq(hc.updated_at)
        expect(hc.score).to eq(400)
      end
    end

    describe '#destroy' do
      it 'correctly updates lmx condition metadata: updates lmx if you delete the most recent of many conditions' do
        FactoryBot.create(:machine_score_xref, location_machine_xref: @lmx, score: 100)
        FactoryBot.create(:machine_score_xref, location_machine_xref: @lmx, score: 200)
        FactoryBot.create(:machine_score_xref, location_machine_xref: @lmx, score: 300)

        expect(@lmx.machine_score_xrefs.first.score).to eq(300)

        @lmx.machine_score_xrefs.first.destroy
        @lmx.reload

        expect(@lmx.machine_score_xrefs.size).to eq(2)
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
