require 'spec_helper'

describe SearchController, type: :controller do
  describe '#autocomplete' do
    it 'returns empty array for terms shorter than 3 characters' do
      get :autocomplete, params: { term: 'ab' }
      expect(JSON.parse(response.body)).to eq([])
    end

    it 'returns empty array for blank term' do
      get :autocomplete, params: { term: '' }
      expect(JSON.parse(response.body)).to eq([])
    end

    it 'returns matching locations' do
      FactoryBot.create(:location, name: 'Ground Kontrol', city: 'Portland', state: 'OR')
      FactoryBot.create(:location, name: 'Unrelated', city: 'Seattle', state: 'WA')

      get :autocomplete, params: { term: 'ground' }

      results = JSON.parse(response.body)
      expect(results.length).to eq(1)
      expect(results.first['label']).to eq('Ground Kontrol (Portland, OR)')
      expect(results.first['id']).to be_present
      expect(results.first['type']).to eq('location')
    end

    it 'returns matching cities' do
      FactoryBot.create(:location, name: 'Foo Bar', city: 'Portland', state: 'OR')
      FactoryBot.create(:location, name: 'Baz Qux', city: 'Portland', state: 'OR')

      get :autocomplete, params: { term: 'port' }

      results = JSON.parse(response.body)
      city_results = results.select { |r| r['type'] == 'city' }
      expect(city_results.length).to eq(1)
      expect(city_results.first['label']).to eq('Portland, OR')
      expect(city_results.first['city']).to eq('Portland')
      expect(city_results.first['state']).to eq('OR')
    end

    it 'returns both locations and cities when both match' do
      FactoryBot.create(:location, name: 'Portland Pinball', city: 'Seattle', state: 'WA')
      FactoryBot.create(:location, name: 'Another Place', city: 'Portland', state: 'OR')

      get :autocomplete, params: { term: 'port' }

      results = JSON.parse(response.body)
      expect(results.map { |r| r['type'] }).to include('location', 'city')
    end

    it 'deduplicates cities' do
      FactoryBot.create(:location, name: 'Venue 1', city: 'Portland', state: 'OR')
      FactoryBot.create(:location, name: 'Venue 2', city: 'Portland', state: 'OR')

      get :autocomplete, params: { term: 'port' }

      results = JSON.parse(response.body)
      city_results = results.select { |r| r['type'] == 'city' }
      expect(city_results.length).to eq(1)
    end

    it 'returns all matching locations without a cap' do
      10.times { |i| FactoryBot.create(:location, name: "Arcade #{i}") }

      get :autocomplete, params: { term: 'arc' }

      results = JSON.parse(response.body)
      location_results = results.select { |r| r['type'] == 'location' }
      expect(location_results.length).to eq(10)
    end

    it 'returns all matching cities without a cap' do
      cities = %w[Portland Portsmith Portchester Portville Porton Portbury]
      cities.each { |c| FactoryBot.create(:location, name: "Venue in #{c}", city: c, state: 'OR') }

      get :autocomplete, params: { term: 'port' }

      results = JSON.parse(response.body)
      city_results = results.select { |r| r['type'] == 'city' }
      expect(city_results.length).to eq(6)
    end
  end
end
