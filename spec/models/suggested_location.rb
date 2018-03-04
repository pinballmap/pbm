require 'spec_helper'

describe SuggestedLocation do
  before(:each) do
    @suggested_location = FactoryBot.create(:suggested_location, id: 1000, region: FactoryBot.create(:region, name: 'chicago'), lat: 1, lon: 2, name: 'foo', street: 'foo', state: 'OR', zip: '97203', city: 'Portland')
    @user = FactoryBot.create(:user, email: 'yeah@ok.com')
  end

  describe '#convert_to_location' do
    it 'should create a rails_admin history entry' do
      @suggested_location.convert_to_location(@user.email)

      results = ActiveRecord::Base.connection.execute(<<HERE)
select message, username, item, month, year from rails_admin_histories limit 1
HERE

      expect(results.values).to eq([['converted from suggested location', 'yeah@ok.com', '1', nil, nil]])
    end
  end
end
