require 'spec_helper'

describe MachineScoreXrefsController, type: :controller do
  before(:each) do
    @lmx = FactoryBot.create(:location_machine_xref, location: FactoryBot.create(:location), machine: FactoryBot.create(:machine))
    @user = FactoryBot.create(:user, username: 'cibw', email: 'yeah@ok.com')
    @msx = FactoryBot.create(:machine_score_xref, location_machine_xref: @lmx, score: 300, user: @user)
  end

  describe 'update' do
    it 'should update a high score that you own as well as high_score in associated user submission' do
      login(@user)
      expect(@msx.score).to eq(300)

      @msx.create_user_submission

      post 'update', params: { score: 400, id: @msx.id }

      @msx.reload
      expect(@msx.score).to eq(400)

      submission = UserSubmission.last

      expect(submission.location).to eq(@lmx.location)
      expect(submission.machine).to eq(@lmx.machine)
      expect(submission.user).to eq(@user)
      expect(submission.submission_type).to eq(UserSubmission::NEW_SCORE_TYPE)
      expect(submission.submission).to eq('cibw added a high score of 400 on Test Machine Name at Test Location Name in Portland.')
      expect(submission.high_score).to eq(400)
    end
  end

  describe 'destroy' do
    it 'should destroy a high score that you own and soft delete the associated user submission with deleted_at' do
      login(@user)
      msx_id = @msx.id

      @msx.create_user_submission

      post 'destroy', params: { id: @msx.id }

      expect(MachineScoreXref.count).to eq(0)
      expect(UserSubmission.last.deleted_at).to_not eq(nil)
    end
  end
end
