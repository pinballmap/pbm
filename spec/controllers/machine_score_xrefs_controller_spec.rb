require 'spec_helper'

describe MachineScoreXrefsController, type: :controller do
  before(:each) do
    @lmx = FactoryBot.create(:location_machine_xref, location: FactoryBot.create(:location), machine: FactoryBot.create(:machine))
    @user = FactoryBot.create(:user, username: 'cibw', email: 'yeah@ok.com')
    @msx = FactoryBot.create(:machine_score_xref, location_machine_xref: @lmx, machine_id: @lmx.machine_id, score: 300, user: @user)
  end

  describe 'new' do
    it 'renders for logged-out users' do
      get 'new'
      expect(response).to be_successful
    end

    it 'assigns all_machines for logged-in users' do
      login(@user)
      get 'new'
      expect(response).to be_successful
      expect(assigns(:all_machines)).not_to be_nil
    end

  end

  describe 'create' do
    it 'should create a high score with populated fields' do
      login(@user)

      post 'create', params: { score: 400, location_machine_xref_id: @lmx.id }

      expect(MachineScoreXref.count).to eq(2)

      msx = MachineScoreXref.last
      expect(msx.machine_id).to eq(@lmx.machine_id)
      expect(msx.user_id).to eq(@user.id)
      expect(msx.score).to eq(400)
    end

    describe 'locationless score' do
      before(:each) do
        login(@user)
        @machine = FactoryBot.create(:machine, name: 'Fireball')
      end

      it 'creates the score with no lmx and redirects with notice' do
        post 'create', params: { machine_id: @machine.id, score: 5000 }

        expect(response).to redirect_to(add_score_path)
        expect(flash[:notice]).to eq('Score added!')

        msx = MachineScoreXref.last
        expect(msx.score).to eq(5000)
        expect(msx.machine_id).to eq(@machine.id)
        expect(msx.location_machine_xref_id).to be_nil
        expect(msx.user).to eq(@user)
      end

      it 'creates a user submission with no location' do
        post 'create', params: { machine_id: @machine.id, score: 5000 }

        submission = UserSubmission.last
        expect(submission.location_name).to be_nil
        expect(submission.location).to be_nil
        expect(submission.submission_type).to eq(UserSubmission::NEW_SCORE_TYPE)
        expect(submission.submission).to include('cibw added a high score of 5,000 on Fireball')
      end

      it 'adds the machine to the life list' do
        post 'create', params: { machine_id: @machine.id, score: 5000 }

        expect(UserMachineXref.where(user: @user, machine_id: @machine.id)).to exist
      end

      it 'redirects with alert for a blank score' do
        post 'create', params: { machine_id: @machine.id, score: '' }

        expect(response).to redirect_to(add_score_path)
        expect(flash[:alert]).to be_present
        expect(MachineScoreXref.count).to eq(1)
      end

      it 'redirects with alert for a non-numeric score' do
        post 'create', params: { machine_id: @machine.id, score: 'fword' }

        expect(response).to redirect_to(add_score_path)
        expect(flash[:alert]).to be_present
        expect(MachineScoreXref.count).to eq(1)
      end
    end
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
      expect(submission.submission).to eq('cibw added a high score of 400 on Test Machine Name at Test Location Name in Portland')
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
