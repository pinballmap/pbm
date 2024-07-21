require 'spec_helper'

describe LocationsController, type: :controller do
  before(:each) do
    @user = FactoryBot.create(:user, username: 'ssw', email: 'ssw@yeah.com', id: 1111)
    login(@user)

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
end
