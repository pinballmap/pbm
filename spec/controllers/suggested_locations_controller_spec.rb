require 'spec_helper'

describe SuggestedLocationsController, type: :controller do
  before(:each) do
    @r = FactoryBot.create(:region, name: 'portland')
    @lt = FactoryBot.create(:location_type, name: 'lt')
    @o = FactoryBot.create(:operator, name: 'o', region: @r)

    @sl = FactoryBot.create(:suggested_location, name: 'name', street: 'street', city: 'city', state: 'OR', zip: '97203', phone: '555-555-5555', lat: 11.11, lon: 22.22, website: 'http://www.cool.com', region: @r, location_type: @lt, operator: @o, machines: 'The Dark Knight (Stern, 2008), Star Trek (Pro) [Stern - 2013], Challenger [Gottlieb - 1971], The Bally Game Show (Bally, 1990), this will not match')

    login
  end

  describe '#convert_to_location' do
    it 'should create a corresponding location, delete itself, redirect to admin page' do
      m_one = FactoryBot.create(:machine, name: 'The Dark Knight', manufacturer: 'Stern', year: '2008')
      m_two = FactoryBot.create(:machine, name: 'Challenger', manufacturer: 'Gottlieb', year: '1971')
      m_three = FactoryBot.create(:machine, name: 'Star Trek (Pro)', manufacturer: 'Stern', year: '2013')
      m_four = FactoryBot.create(:machine, name: 'The Bally Game Show', manufacturer: 'Bally', year: '1990')

      FactoryBot.create(:machine, name: 'Challenger', manufacturer: 'Stern', year: '1971')
      FactoryBot.create(:machine, name: 'Challenger', manufacturer: 'Gottlieb', year: '2222')

      post :convert_to_location, format: :json, params: { id: @sl.id }
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

      (lmx_one, lmx_two, lmx_three, lmx_four) = LocationMachineXref.all
      expect(lmx_one.location).to eq(l)
      expect(lmx_one.machine).to eq(m_one)
      expect(lmx_two.location).to eq(l)
      expect(lmx_two.machine).to eq(m_three)
      expect(lmx_three.location).to eq(l)
      expect(lmx_three.machine).to eq(m_two)
      expect(lmx_four.location).to eq(l)
      expect(lmx_four.machine).to eq(m_four)

      expect(response).to redirect_to('/admin')
    end

    it 'should throw an error when failing a field validation' do
      post :convert_to_location, format: :json, params: { id: FactoryBot.create(:suggested_location).id }

      expect(SuggestedLocation.all.size).to eq(2)
      expect(Location.all.size).to eq(0)
    end
  end
end
