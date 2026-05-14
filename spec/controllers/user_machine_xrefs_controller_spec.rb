require 'spec_helper'

describe UserMachineXrefsController, type: :controller do
  before(:each) do
    @user = FactoryBot.create(:user, username: 'cibw', email: 'yeah@ok.com')
    @machine = FactoryBot.create(:machine)
  end

  describe 'create' do
    it 'adds a machine to the life list' do
      login(@user)

      post 'create', params: { machine_id: @machine.id }

      expect(UserMachineXref.count).to eq(1)
      expect(UserMachineXref.first.user).to eq(@user)
      expect(UserMachineXref.first.machine).to eq(@machine)
    end

    it 'adds multiple machines to the life list in one request' do
      login(@user)
      other_machine = FactoryBot.create(:machine)

      post 'create', params: { machine_id: [ @machine.id, other_machine.id ] }

      expect(UserMachineXref.count).to eq(2)
    end

    it 'does not create a duplicate entry' do
      login(@user)

      post 'create', params: { machine_id: @machine.id }
      post 'create', params: { machine_id: @machine.id }

      expect(UserMachineXref.count).to eq(1)
    end

    it 'requires login' do
      post 'create', params: { machine_id: @machine.id }

      expect(UserMachineXref.count).to eq(0)
    end
  end

  describe 'destroy' do
    before(:each) do
      @umx = FactoryBot.create(:user_machine_xref, user: @user, machine: @machine)
    end

    it 'removes machine from life list' do
      login(@user)

      post 'destroy', params: { id: @umx.id }

      expect(UserMachineXref.count).to eq(0)
    end

    it 'does not remove the machine from the life list when scores exist' do
      login(@user)
      lmx = FactoryBot.create(:location_machine_xref, machine: @machine)
      FactoryBot.create(:machine_score_xref, user: @user, machine: @machine, location_machine_xref: lmx)

      post 'destroy', params: { id: @umx.id }

      expect(response).to have_http_status(:unprocessable_content)
      expect(UserMachineXref.count).to eq(1)
      expect(MachineScoreXref.count).to eq(1)
    end

    it 'does not remove another user\'s life list entry' do
      login(@user)
      other_user = FactoryBot.create(:user)
      other_umx = FactoryBot.create(:user_machine_xref, user: other_user, machine: @machine)

      post 'destroy', params: { id: other_umx.id }

      expect(UserMachineXref.count).to eq(2)
    end
  end
end
