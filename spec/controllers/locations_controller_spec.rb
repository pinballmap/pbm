require 'spec_helper'

describe LocationsController, type: :controller do
  before(:each) do
    login

    region = FactoryBot.create(:region, name: 'portland')
    @location = FactoryBot.create(:location, id: 777, region: region)
    @machine = FactoryBot.create(:machine)
    FactoryBot.create(:user, email: 'foo@bar.com', region: region)
  end

  describe '#update_metadata' do
    it 'should return error json when phone number is in an invalid format' do
      get 'update_metadata', params: { region: 'portland', id: @location.id, new_phone_777: 'invalid' }

      expect(response.body).to eq('{"error":"Invalid phone format."}')
    end

    it 'should return error json when website is in an invalid format' do
      get 'update_metadata', params: { region: 'portland', id: @location.id, new_website_777: 'invalid' }

      expect(response.body).to eq('{"error":"Website must begin with http:// or https://"}')
    end
  end
  describe '#newest_machine_name' do
    it 'should tell you the name of the newest machine added to the location' do
      FactoryBot.create(:location_machine_xref, location_id: @location.id, machine: FactoryBot.create(:machine, name: 'cool'))
      get 'newest_machine_name', params: { region: 'portland', id: @location.id }

      expect(response.body).to eq('cool')
    end
  end
end
