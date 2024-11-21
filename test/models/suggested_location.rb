require 'spec_helper'

describe SuggestedLocation do
  before(:each) do
    @suggested_location = FactoryBot.create(:suggested_location, id: 1000, region: FactoryBot.create(:region, name: 'chicago'), lat: 1, lon: 2, name: 'foo', street: 'foo', state: 'OR', zip: '97203', city: 'Portland', machines: 'Batman')
    @user = FactoryBot.create(:user, email: 'yeah@ok.com')
  end

  describe 'after_create' do
    it 'should put http:// in front of websites without one' do
      expect(@suggested_location.website).must_be_same_as nil

      location_with_complete_website = FactoryBot.create(:suggested_location, name: 'foo', machines: 'Batman', website: 'http://foo.com')
      expect(location_with_complete_website.website).must_equal 'http://foo.com'

      location_with_incomplete_website = FactoryBot.create(:suggested_location, name: 'foo', machines: 'Batman', website: 'bar.com')
      expect(location_with_incomplete_website.website).must_equal 'http://bar.com'

      location_with_incomplete_website = FactoryBot.create(:suggested_location, name: 'foo', machines: 'Batman', website: '')
      expect(location_with_incomplete_website.website).must_equal ''

      expect(@suggested_location.country).must_equal 'US'

      filled_in_country = FactoryBot.create(:suggested_location, name: 'foo', machines: 'Batman', country: 'FR')
      expect(filled_in_country.country).must_equal 'FR'
    end

    it 'should tag the location with US as the country if no country is sent' do
      expect(@suggested_location.website).must_be_same_as nil

      location_with_complete_website = FactoryBot.create(:suggested_location, name: 'foo', machines: 'Batman', website: 'http://foo.com')
      expect(location_with_complete_website.website).must_equal 'http://foo.com'

      location_with_incomplete_website = FactoryBot.create(:suggested_location, name: 'foo', machines: 'Batman', website: 'bar.com')
      expect(location_with_incomplete_website.website).must_equal 'http://bar.com'
    end

    it 'should strip starting and ending whitespace' do
      location_with_whitespace = FactoryBot.create(:suggested_location, name: ' foo ', machines: 'Batman')
      expect(location_with_whitespace.name).must_equal 'foo'
    end
  end

  describe '#address_incomplete?' do
    it 'should be true based on lack of address' do
      refute @suggested_location.address_incomplete?

      @suggested_location.state = nil
      refute @suggested_location.address_incomplete?

      @suggested_location.zip = nil
      refute @suggested_location.address_incomplete?

      @suggested_location.street = nil
      assert @suggested_location.address_incomplete?
    end
  end

  describe '#convert_to_location' do
    it 'should create a rails_admin history entry' do
      @suggested_location.convert_to_location(@user.email)

      results = ActiveRecord::Base.connection.execute(<<HERE)
select event, item_type, item_id from versions order by created_at limit 1
HERE

      expect(results.values).must_equal [['converted from suggested location', 'Location', 1]]
    end

    it 'requires country' do
      @suggested_location.country = nil
      @suggested_location.convert_to_location(@user.email)

      expect(@suggested_location.errors.messages).must_include base: ['Country is a required field for conversion.']
    end
  end
end
