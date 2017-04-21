require 'spec_helper'

describe SuggestedLocationsController, type: :controller do
  before(:each) do
    login

    @r = FactoryGirl.create(:region, name: 'portland')
    @lt = FactoryGirl.create(:location_type, name: 'lt')
    @o = FactoryGirl.create(:operator, name: 'o')

    @sl = FactoryGirl.create(:suggested_location, name: 'name', street: 'street', city: 'city', state: 'OR', zip: '97203', phone: '555-555-5555', lat: 11.11, lon: 22.22, website: 'http://www.cool.com', region: @r, location_type: @lt, operator: @o)
  end

  describe '#convert_to_location' do
    it 'should create a corresponding location, delete itself, redirect to admin page' do
      post :convert_to_location, format: :json, id: @sl.id

      l = Location.find_by_name('name')
      expect(l.name).to eq('name')
      expect(l.street).to eq('street')
      expect(l.city).to eq('city')
      expect(l.state).to eq('OR')
      expect(l.zip).to eq('97203')
      expect(l.phone).to eq('555-555-5555')
      expect(l.lat).to eq(11.11)
      expect(l.lon).to eq(22.22)
      expect(l.website).to eq('http://www.cool.com')
      expect(l.region).to eq(@r)
      expect(l.location_type).to eq(@lt)
      expect(l.operator).to eq(@o)

      expect(SuggestedLocation.all.size).to eq(0)

      expect(response).to redirect_to('/admin')
    end
  end
end
