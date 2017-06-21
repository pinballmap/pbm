require 'spec_helper'

describe SuggestedLocationsController, type: :controller do
  before(:each) do
    login

    @r = FactoryGirl.create(:region, name: 'portland')
    @lt = FactoryGirl.create(:location_type, name: 'lt')
    @o = FactoryGirl.create(:operator, name: 'o')

    @sl = FactoryGirl.create(:suggested_location, name: 'name', street: 'street', city: 'city', state: 'OR', zip: '97203', phone: '555-555-5555', lat: 11.11, lon: 22.22, website: 'http://www.cool.com', region: @r, location_type: @lt, operator: @o, machines: 'The Dark Knight (Stern, 2008), Challenger [Gottlieb - 1971], this will not match')
  end

  describe '#convert_to_location' do
    it 'should create a corresponding location, delete itself, redirect to admin page' do
      m_one = FactoryGirl.create(:machine, name: 'The Dark Knight', manufacturer: 'Stern', year: '2008')
      m_two = FactoryGirl.create(:machine, name: 'Challenger', manufacturer: 'Gottlieb', year: '1971')

      FactoryGirl.create(:machine, name: 'Challenger', manufacturer: 'Stern', year: '1971')
      FactoryGirl.create(:machine, name: 'Challenger', manufacturer: 'Gottlieb', year: '2222')

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

      (lmx_one, lmx_two) = LocationMachineXref.all
      expect(lmx_one.location).to eq(l)
      expect(lmx_one.machine).to eq(m_one)
      expect(lmx_two.location).to eq(l)
      expect(lmx_two.machine).to eq(m_two)

      expect(response).to redirect_to('/admin')
    end

    it 'should throw an error when failing a field validation' do
      post :convert_to_location, format: :json, id: FactoryGirl.create(:suggested_location).id

      expect(SuggestedLocation.all.size).to eq(2)
      expect(Location.all.size).to eq(0)
    end
  end
end
