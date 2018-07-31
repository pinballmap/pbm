require 'spec_helper'

describe SuggestedLocation do
  before(:each) do
    @suggested_location = FactoryBot.create(:suggested_location, id: 1000, region: FactoryBot.create(:region, name: 'chicago'), lat: 1, lon: 2, name: 'foo', street: 'foo', state: 'OR', zip: '97203', city: 'Portland')
    @user = FactoryBot.create(:user, email: 'yeah@ok.com')
  end

  describe 'after_create' do
    it 'should put http:// in front of websites without one' do
      expect(@suggested_location.website).to be(nil)

      location_with_complete_website = FactoryBot.create(:suggested_location, website: 'http://foo.com')
      expect(location_with_complete_website.website).to eq('http://foo.com')

      location_with_incomplete_website = FactoryBot.create(:suggested_location, website: 'bar.com')
      expect(location_with_incomplete_website.website).to eq('http://bar.com')

      expect(@suggested_location.country).to eq('US')

      filled_in_country = FactoryBot.create(:suggested_location, country: 'FR')
      expect(filled_in_country.country).to eq('FR')
    end

    it 'should tag the location with US as the country if no country is sent' do
      expect(@suggested_location.website).to be(nil)

      location_with_complete_website = FactoryBot.create(:suggested_location, website: 'http://foo.com')
      expect(location_with_complete_website.website).to eq('http://foo.com')

      location_with_incomplete_website = FactoryBot.create(:suggested_location, website: 'bar.com')
      expect(location_with_incomplete_website.website).to eq('http://bar.com')
    end
  end

  describe '#address_incomplete?' do
    it 'should be true based on lack of address' do
      expect(@suggested_location.address_incomplete?).to be(false)

      @suggested_location.state = nil
      expect(@suggested_location.address_incomplete?).to be(false)

      @suggested_location.zip = nil
      expect(@suggested_location.address_incomplete?).to be(false)

      @suggested_location.street = nil
      expect(@suggested_location.address_incomplete?).to be(true)
    end
  end

  describe '#convert_to_location' do
    it 'should create a rails_admin history entry' do
      @suggested_location.convert_to_location(@user.email)

      results = ActiveRecord::Base.connection.execute(<<HERE)
select message, username, item, month, year from rails_admin_histories limit 1
HERE

      expect(results.values).to eq([['converted from suggested location', 'yeah@ok.com', 1, nil, nil]])
    end
  end
end
