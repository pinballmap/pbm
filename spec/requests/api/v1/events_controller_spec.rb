require 'spec_helper'

describe Api::V1::EventsController, type: :request do
  let(:location) { FactoryBot.create(:location, name: 'Ground Kontrol', lat: 45.524, lon: -122.676) }

  def event(attrs = {})
    FactoryBot.create(:event, {
      name: 'Strikes', start_date: Date.current + 3, end_date: Date.current + 3, address: '115 NW 5th Ave Portland, OR 97209',
      latitude: 45.524, longitude: -122.676, ifpa_tournament_id: 1001, external_link: 'https://example.com',
      event_type: 'Tournament', long_desc: 'Details'
    }.merge(attrs))
  end

  def json
    JSON.parse(response.body)
  end

  it 'never geocodes imported events' do
    expect(Geocoder).not_to receive(:search)
    event(latitude: nil, longitude: nil)
  end

  describe '#index' do
    it 'returns upcoming events at a location, by start date, with the fields the location view shows and no address' do
      later = event(location: location, name: 'Later', start_date: Date.current + 10, end_date: Date.current + 10)
      sooner = event(location: location, name: 'Sooner')
      event(name: 'Elsewhere')

      get '/api/v1/events.json', params: { location_id: location.id }

      expect(response).to be_successful
      expect(json['events'].map { |e| e['id'] }).to eq([ sooner.id, later.id ])
      expect(json['events'].first).to eq(
        'id' => sooner.id, 'name' => 'Sooner', 'start_date' => sooner.start_date.iso8601, 'end_date' => sooner.end_date.iso8601,
        'ifpa_tournament_id' => 1001, 'external_link' => 'https://example.com', 'event_type' => 'Tournament', 'long_desc' => 'Details'
      )
    end

    it 'returns upcoming events within the radius, with the detail fields' do
      near = event(name: 'Near', external_location_name: 'Ground Kontrol Arcade')
      event(name: 'Far', latitude: 47.6, longitude: -122.3)

      get '/api/v1/events.json', params: { lat: '45.52', lon: '-122.68', radius: '50' }

      expect(json['events'].map { |e| e['name'] }).to eq([ 'Near' ])
      expect(json['events'].first).to eq(
        'id' => near.id, 'ifpa_tournament_id' => 1001, 'name' => 'Near', 'start_date' => near.start_date.iso8601,
        'end_date' => near.end_date.iso8601, 'address' => near.address, 'external_location_name' => 'Ground Kontrol Arcade',
        'external_link' => 'https://example.com', 'event_type' => 'Tournament', 'long_desc' => 'Details', 'location_id' => nil,
        'location_name' => nil
      )
    end

    it 'paginates events within the radius, 50 per page' do
      51.times { |i| event(name: "Event #{i.to_s.rjust(2, '0')}") }

      get '/api/v1/events.json', params: { lat: '45.52', lon: '-122.68', radius: '50' }

      expect(json['events'].size).to eq(50)
      expect(json['pagy']).to include('count' => 51, 'page' => 1, 'pages' => 2, 'next' => 2)

      get '/api/v1/events.json', params: { lat: '45.52', lon: '-122.68', radius: '50', page: 2 }

      expect(json['events'].map { |e| e['name'] }).to eq([ 'Event 50' ])
      expect(json['pagy']).to include('page' => 2, 'previous' => 1)
      expect(json['pagy']).not_to have_key('next')
    end

    it 'does not paginate events at a location' do
      51.times { event(location: location) }

      get '/api/v1/events.json', params: { location_id: location.id }

      expect(json['events'].size).to eq(51)
      expect(json).not_to have_key('pagy')
    end

    it 'includes the location name for events within the radius that are at a location' do
      event(location: location, name: 'At Ground Kontrol')
      event(name: 'Not at a location', start_date: Date.current + 4, end_date: Date.current + 4)

      get '/api/v1/events.json', params: { lat: '45.52', lon: '-122.68', radius: '50' }

      expect(json['events'].map { |e| [ e['name'], e['location_name'] ] }).to eq([ [ 'At Ground Kontrol', 'Ground Kontrol' ], [ 'Not at a location', nil ] ])
    end

    it 'honors kilometers' do
      event(latitude: 45.95, longitude: -122.68) # about 30 miles / 48 km north

      get '/api/v1/events.json', params: { lat: '45.52', lon: '-122.68', radius: '40', distance_unit: 'k' }
      expect(json['events']).to be_empty

      get '/api/v1/events.json', params: { lat: '45.52', lon: '-122.68', radius: '40', distance_unit: 'm' }
      expect(json['events'].size).to eq(1)
    end

    it "hides events that ended before the client's date" do
      event(location: location, name: 'Yesterday', start_date: Date.current - 1, end_date: Date.current - 1)
      event(location: location, name: 'Today', start_date: Date.current, end_date: Date.current)

      get '/api/v1/events.json', params: { location_id: location.id, start_date: Date.current.iso8601 }

      expect(json['events'].map { |e| e['name'] }).to eq([ 'Today' ])
    end

    it 'keeps events for two days after they end when the client date is missing or implausible' do
      event(location: location, name: 'Two days ago', start_date: Date.current - 2, end_date: Date.current - 2)
      event(location: location, name: 'Three days ago', start_date: Date.current - 3, end_date: Date.current - 3)

      get '/api/v1/events.json', params: { location_id: location.id }
      expect(json['events'].map { |e| e['name'] }).to eq([ 'Two days ago' ])

      get '/api/v1/events.json', params: { location_id: location.id, start_date: (Date.current + 30).iso8601 }
      expect(json['events'].map { |e| e['name'] }).to eq([ 'Two days ago' ])
    end

    it 'shows multi-day events that are still running' do
      event(location: location, start_date: Date.current - 5, end_date: Date.current + 1)

      get '/api/v1/events.json', params: { location_id: location.id, start_date: Date.current.iso8601 }

      expect(json['events'].size).to eq(1)
    end

    it 'rejects bad params' do
      [
        {},
        { location_id: 'abc' },
        { lat: '45.5', lon: '-122.6' },
        { lat: '45.5', lon: '-122.6', radius: '251' },
        { lat: '95', lon: '-122.6', radius: '50' },
        { lat: '45.5', lon: '-122.6', radius: '50', distance_unit: 'x' }
      ].each do |params|
        get '/api/v1/events.json', params: params
        expect(response).to have_http_status(:bad_request), "expected 400 for #{params}"
      end
    end
  end

  describe '#show' do
    it 'returns detail fields, with the name of the location' do
      e = event(location: location, external_location_name: 'Ground Kontrol Arcade')

      get "/api/v1/events/#{e.id}.json"

      expect(json['event']).to eq(
        'id' => e.id, 'ifpa_tournament_id' => 1001, 'name' => 'Strikes', 'start_date' => e.start_date.iso8601,
        'end_date' => e.end_date.iso8601, 'address' => e.address, 'external_location_name' => 'Ground Kontrol Arcade',
        'external_link' => 'https://example.com', 'event_type' => 'Tournament', 'long_desc' => 'Details', 'location_id' => location.id,
        'location_name' => 'Ground Kontrol'
      )
    end

    it 'returns a null location_name for an event not at a location' do
      e = event(external_location_name: 'Somewhere Else')

      get "/api/v1/events/#{e.id}.json"

      expect(json['event']['location_id']).to be_nil
      expect(json['event']['location_name']).to be_nil
    end

    it 'returns 404 for a missing event' do
      get '/api/v1/events/0.json'

      expect(response).to have_http_status(:not_found)
    end
  end
end
