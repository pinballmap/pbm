require 'spec_helper'

describe EventsController, type: :controller do
  let(:bounds_params) do
    {
      boundsData: {
        sw: { lat: '45.0', lng: '-123.5' },
        ne: { lat: '46.0', lng: '-122.0' }
      }
    }
  end

  describe '#list_within_range' do
    render_views

    before(:each) do
      @location = FactoryBot.create(:location, name: 'Ground Kontrol', lat: '45.6008356', lon: '-122.760606')
    end

    it 'lists upcoming matched and unmatched events within the bounding box, sorted by start date' do
      FactoryBot.create(:event, location: @location, name: 'Monday Strikes', start_date: Date.new(2030, 1, 7), end_date: Date.new(2030, 1, 7))
      FactoryBot.create(:event, name: 'Unmatched Event', start_date: Date.new(2030, 1, 5), end_date: Date.new(2030, 1, 5),
        ifpa_tournament_id: 1001, external_location_name: 'Some Bar', address: '123 Main St, Portland, OR', latitude: 45.5, longitude: -122.6)
      FactoryBot.create(:event, location: @location, name: 'Old Event', start_date: Date.current - 10, end_date: Date.current - 10)
      FactoryBot.create(:event, name: 'Distant Event', start_date: Date.new(2030, 1, 7), end_date: Date.new(2030, 1, 7),
        ifpa_tournament_id: 1002, latitude: 12.0, longitude: -12.0)

      get 'list_within_range', params: bounds_params

      expect(response).to be_successful
      expect(assigns(:events).map(&:name)).to eq([ 'Unmatched Event', 'Monday Strikes' ])
      expect(response.body).to include('2 upcoming events within the map view')
      expect(response.body).to include("href=\"/map?by_location_id=#{@location.id}\">Ground Kontrol</a>")
      expect(response.body).to include('Some Bar', '123 Main St, Portland, OR')
      expect(response.body).to_not include('Old Event', 'Distant Event')
    end

    it 'says so when there are no events within the bounding box' do
      get 'list_within_range', params: bounds_params

      expect(response).to be_successful
      expect(response.body).to include('No upcoming events within the map view')
    end

    it 'returns a 400 instead of raising when boundsData is missing' do
      get 'list_within_range'

      expect(response).to have_http_status(:bad_request)
    end
  end
end
