require 'spec_helper'

describe LocationMachineXrefsController, type: :controller do
  before(:each) do
    @region = FactoryBot.create(:region, name: 'portland')
    @location = FactoryBot.create(:location, id: 1)
    @user = FactoryBot.create(:user, username: 'ssw', email: 'ssw@yeah.com')
    FactoryBot.create(:user, email: 'foo@bar.com', region: @region)
  end

  describe 'render_machine_scores' do
    render_views

    it 'only returns scores belonging to the current user' do
      machine = FactoryBot.create(:machine)
      lmx = FactoryBot.create(:location_machine_xref, location: @location, machine: machine)
      other_user = FactoryBot.create(:user)

      FactoryBot.create(:machine_score_xref, location_machine_xref: lmx, machine_id: machine.id, score: 1000, user: @user)
      FactoryBot.create(:machine_score_xref, location_machine_xref: lmx, machine_id: machine.id, score: 9999, user: other_user)

      login(@user)
      get 'render_machine_scores', params: { id: lmx.id }

      expect(response.body).to include('1,000')
      expect(response.body).not_to include('9,999')
    end
  end

  describe 'create' do
    it "should return undef if you don't supply a machine name or id" do
      login(@user)

      post 'create', params: { region: 'portland', add_machine_by_id_1: '', add_machine_by_name_1: '', location_id: @location.id }
      expect(LocationMachineXref.all.size).to eq(0)
    end

    it 'tags the new lmx ic_enabled true when ic_enabled param is true and the machine is ic_eligible' do
      machine = FactoryBot.create(:machine, ic_eligible: true)
      login(@user)

      post 'create', params: { region: 'portland', add_machine_by_id_1: machine.id, location_id: @location.id, "ic_enabled_1": 'true' }

      lmx = LocationMachineXref.find_by(location_id: @location.id, machine_id: machine.id)
      expect(lmx.ic_enabled).to eq(true)
      expect(UserSubmission.where(submission_type: UserSubmission::IC_TOGGLE_TYPE).count).to eq(1)
    end

    it 'tags the new lmx ic_enabled false when ic_enabled param is false and the machine is ic_eligible' do
      machine = FactoryBot.create(:machine, ic_eligible: true)
      login(@user)

      post 'create', params: { region: 'portland', add_machine_by_id_1: machine.id, location_id: @location.id, "ic_enabled_1": 'false' }

      lmx = LocationMachineXref.find_by(location_id: @location.id, machine_id: machine.id)
      expect(lmx.ic_enabled).to eq(false)
      expect(UserSubmission.where(submission_type: UserSubmission::IC_TOGGLE_TYPE).count).to eq(1)
    end

    it 'ignores the ic_enabled param when the machine is not ic_eligible' do
      machine = FactoryBot.create(:machine, ic_eligible: false)
      login(@user)

      post 'create', params: { region: 'portland', add_machine_by_id_1: machine.id, location_id: @location.id, "ic_enabled_1": 'true' }

      lmx = LocationMachineXref.find_by(location_id: @location.id, machine_id: machine.id)
      expect(lmx.ic_enabled).to eq(nil)
      expect(UserSubmission.where(submission_type: UserSubmission::IC_TOGGLE_TYPE).count).to eq(0)
    end

    it 'creates a machine_condition for the new lmx when a condition param is present' do
      machine = FactoryBot.create(:machine)
      login(@user)

      post 'create', params: { region: 'portland', add_machine_by_id_1: machine.id, location_id: @location.id, "machine_condition_1": 'Great shape' }

      lmx = LocationMachineXref.find_by(location_id: @location.id, machine_id: machine.id)
      expect(lmx.machine_conditions.first.comment).to eq('Great shape')
      expect(UserSubmission.where(submission_type: UserSubmission::NEW_CONDITION_TYPE).count).to eq(1)
    end

    it 'does not create a machine_condition when the condition param is blank' do
      machine = FactoryBot.create(:machine)
      login(@user)

      post 'create', params: { region: 'portland', add_machine_by_id_1: machine.id, location_id: @location.id, "machine_condition_1": '' }

      lmx = LocationMachineXref.find_by(location_id: @location.id, machine_id: machine.id)
      expect(lmx.machine_conditions).to be_empty
      expect(UserSubmission.where(submission_type: UserSubmission::NEW_CONDITION_TYPE).count).to eq(0)
    end

    it 'does not create a machine_condition when it contains <a href' do
      machine = FactoryBot.create(:machine)
      login(@user)

      post 'create', params: { region: 'portland', add_machine_by_id_1: machine.id, location_id: @location.id, "machine_condition_1": 'spam <a href' }

      lmx = LocationMachineXref.find_by(location_id: @location.id, machine_id: machine.id)
      expect(lmx.machine_conditions).to be_empty
    end

    it 'creates all three user_submissions when adding an ic_eligible machine with ic status and a condition' do
      machine = FactoryBot.create(:machine, ic_eligible: true)
      login(@user)

      post 'create', params: { region: 'portland', add_machine_by_id_1: machine.id, location_id: @location.id, "ic_enabled_1": 'true', "machine_condition_1": 'Great shape' }

      expect(UserSubmission.count).to eq(3)
      expect(UserSubmission.where(submission_type: UserSubmission::NEW_LMX_TYPE).count).to eq(1)
      expect(UserSubmission.where(submission_type: UserSubmission::IC_TOGGLE_TYPE).count).to eq(1)
      expect(UserSubmission.where(submission_type: UserSubmission::NEW_CONDITION_TYPE).count).to eq(1)
    end

    it 'only creates the new_lmx user_submission when neither ic status nor a condition is supplied' do
      machine = FactoryBot.create(:machine, ic_eligible: true)
      login(@user)

      post 'create', params: { region: 'portland', add_machine_by_id_1: machine.id, location_id: @location.id }

      expect(UserSubmission.count).to eq(1)
      expect(UserSubmission.first.submission_type).to eq(UserSubmission::NEW_LMX_TYPE)
    end
  end
end
