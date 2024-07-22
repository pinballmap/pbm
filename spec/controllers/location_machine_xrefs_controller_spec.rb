require 'spec_helper'

describe LocationMachineXrefsController, type: :controller do
  before(:each) do
    @region = FactoryBot.create(:region, name: 'portland')
    @location = FactoryBot.create(:location, id: 1)
    @user = FactoryBot.create(:user, username: 'ssw', email: 'ssw@yeah.com')
    FactoryBot.create(:user, email: 'foo@bar.com', region: @region)
  end

  describe 'create' do
    it "should return undef if you don't supply a machine name or id" do
      login(@user)

      post 'create', params: { region: 'portland', add_machine_by_id_1: '', add_machine_by_name_1: '', location_id: @location.id }
      expect(LocationMachineXref.all.size).to eq(0)
    end
  end
end
