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
  end
end
