require 'spec_helper'

describe SuggestedLocation do
  before(:each) do
    @suggested_location = FactoryBot.create(:suggested_location, id: 1000, region: FactoryBot.create(:region, name: 'chicago'), lat: 1, lon: 2, name: 'foo', street: 'foo', state: 'OR', zip: '97203', city: 'Portland', machines: 'Batman')
    @user = FactoryBot.create(:user, email: 'yeah@ok.com')
  end

  describe 'after_create' do
    it 'should put http:// in front of websites without one' do
      expect(@suggested_location.website).to be(nil)

      location_with_complete_website = FactoryBot.create(:suggested_location, name: 'foo', machines: 'Batman', website: 'http://foo.com')
      expect(location_with_complete_website.website).to eq('http://foo.com')

      location_with_incomplete_website = FactoryBot.create(:suggested_location, name: 'foo', machines: 'Batman', website: 'bar.com')
      expect(location_with_incomplete_website.website).to eq('http://bar.com')

      location_with_incomplete_website = FactoryBot.create(:suggested_location, name: 'foo', machines: 'Batman', website: '')
      expect(location_with_incomplete_website.website).to eq('')

      expect(@suggested_location.country).to eq('US')

      filled_in_country = FactoryBot.create(:suggested_location, name: 'foo', machines: 'Batman', country: 'FR')
      expect(filled_in_country.country).to eq('FR')
    end

    it 'should tag the location with US as the country if no country is sent' do
      expect(@suggested_location.website).to be(nil)

      location_with_complete_website = FactoryBot.create(:suggested_location, name: 'foo', machines: 'Batman', website: 'http://foo.com')
      expect(location_with_complete_website.website).to eq('http://foo.com')

      location_with_incomplete_website = FactoryBot.create(:suggested_location, name: 'foo', machines: 'Batman', website: 'bar.com')
      expect(location_with_incomplete_website.website).to eq('http://bar.com')
    end

    it 'should strip starting and ending whitespace' do
      location_with_whitespace = FactoryBot.create(:suggested_location, name: ' foo ', machines: 'Batman')
      expect(location_with_whitespace.name).to eq('foo')
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
select event, item_type, item_id from versions order by created_at limit 1
HERE

      expect(results.values).to eq([ [ 'converted from suggested location', 'Location', 1 ] ])
    end

    it 'requires country' do
      @suggested_location.country = nil
      @suggested_location.convert_to_location(@user.email)

      expect(@suggested_location.errors.messages).to include(base: [ 'Country is a required field for conversion.' ])
    end
  end
end
