require 'spec_helper'

describe LocationsController, type: :controller do
  before(:each) do
    login

    region = FactoryGirl.create(:region, name: 'portland')
    @location = FactoryGirl.create(:location, id: 777, region: region)
    @machine = FactoryGirl.create(:machine)
    FactoryGirl.create(:user, email: 'foo@bar.com', region: region)
  end

  describe '#update_metadata' do
    it 'should return error json when phone number is in an invalid format' do
      get 'update_metadata', region: 'portland', id: @location.id, new_phone_777: 'invalid'

      expect(response.body).to eq('{"error":"Phone format invalid, please use ###-###-####"}')
    end

    it 'should return error json when website is in an invalid format' do
      get 'update_metadata', region: 'portland', id: @location.id, new_website_777: 'invalid'

      expect(response.body).to eq('{"error":"Website must begin with http:// or https://"}')
    end
  end
  describe '#newest_machine_name' do
    it 'should tell you the name of the newest machine added to the location' do
      FactoryGirl.create(:location_machine_xref, location_id: @location.id, machine: FactoryGirl.create(:machine, name: 'cool'))
      get 'newest_machine_name', region: 'portland', id: @location.id

      expect(response.body).to eq('cool')
    end
  end
end
