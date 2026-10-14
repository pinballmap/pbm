require 'spec_helper'

describe Api::V1::PlacesController, type: :request do
  before(:each) do
    @user = FactoryBot.create(:user, email: 'foo@bar.test', authentication_token: '1G8_s7P-V-4MGojaKD7a')
    @auth_headers = { 'X-User-Email' => 'foo@bar.test', 'X-User-Token' => '1G8_s7P-V-4MGojaKD7a' }

    @requested_uris = []
    google_response = instance_double(Net::HTTPOK, body: '{"status":"OK","predictions":[]}', code: '200')
    http = instance_double(Net::HTTP)
    allow(http).to receive(:get) { |path| @requested_uris << path; google_response }
    allow(Net::HTTP).to receive(:start).and_yield(http)
  end

  def requested_query
    Rack::Utils.parse_query(URI(@requested_uris.last).query)
  end

  describe '#autocomplete' do
    it 'requires a logged in user' do
      get '/api/v1/places/place/autocomplete/json', params: { input: 'pizza' }

      expect(JSON.parse(response.body)['errors']).to eq(ApplicationController::AUTH_REQUIRED_MSG)
      expect(Net::HTTP).not_to have_received(:start)
    end

    it 'forwards allow-listed params plus the server key and returns the Google response' do
      ENV['GOOGLE_PLACES_API_KEY'] = 'server-key'

      get '/api/v1/places/place/autocomplete/json', params: { input: 'pizza', language: 'en', sessiontoken: 'abc-123', key: 'client-key', radius: '50000' }, headers: @auth_headers

      expect(response).to be_successful
      expect(JSON.parse(response.body)).to eq({ 'status' => 'OK', 'predictions' => [] })
      expect(@requested_uris.last).to start_with('/maps/api/place/autocomplete/json?')
      expect(requested_query).to eq('input' => 'pizza', 'language' => 'en', 'sessiontoken' => 'abc-123', 'key' => 'server-key')
    ensure
      ENV.delete('GOOGLE_PLACES_API_KEY')
    end

    it 'drops malformed language and sessiontoken values' do
      get '/api/v1/places/place/autocomplete/json', params: { input: 'pizza', language: 'en&key=x', sessiontoken: 'a b' }, headers: @auth_headers

      expect(requested_query.keys).to contain_exactly('input', 'key')
    end

    it 'rejects a blank or overly long input' do
      get '/api/v1/places/place/autocomplete/json', params: { input: ' ' }, headers: @auth_headers
      expect(response.status).to eq(400)

      get '/api/v1/places/place/autocomplete/json', params: { input: 'a' * 201 }, headers: @auth_headers
      expect(response.status).to eq(400)

      expect(Net::HTTP).not_to have_received(:start)
    end

    it 'stops forwarding once the global daily limit is reached' do
      allow(Rails.cache).to receive(:increment).and_call_original
      allow(Rails.cache).to receive(:increment).with(/\Aplaces:autocomplete:/, any_args).and_return(Api::V1::PlacesController::DAILY_LIMITS['autocomplete'] + 1)

      get '/api/v1/places/place/autocomplete/json', params: { input: 'pizza' }, headers: @auth_headers

      expect(response.status).to eq(503)
      expect(Net::HTTP).not_to have_received(:start)
    end

    it 'returns a 502 when Google times out' do
      allow(Net::HTTP).to receive(:start).and_raise(Net::ReadTimeout)

      get '/api/v1/places/place/autocomplete/json', params: { input: 'pizza' }, headers: @auth_headers

      expect(response.status).to eq(502)
      expect(JSON.parse(response.body)['status']).to eq('UNKNOWN_ERROR')
    end
  end

  describe '#details' do
    it 'requires a logged in user' do
      get '/api/v1/places/place/details/json', params: { placeid: 'ChIJ123' }

      expect(JSON.parse(response.body)['errors']).to eq(ApplicationController::AUTH_REQUIRED_MSG)
      expect(Net::HTTP).not_to have_received(:start)
    end

    it 'always requests the fixed field list, ignoring client-supplied fields' do
      get '/api/v1/places/place/details/json', params: { placeid: 'ChIJ123', language: 'en', sessiontoken: 'abc-123', fields: 'reviews,photos' }, headers: @auth_headers

      expect(response).to be_successful
      expect(@requested_uris.last).to start_with('/maps/api/place/details/json?')
      expect(requested_query).to include('placeid' => 'ChIJ123', 'language' => 'en', 'sessiontoken' => 'abc-123', 'fields' => Api::V1::PlacesController::DETAILS_FIELDS)
      expect(requested_query['fields']).not_to include('reviews')
    end

    it 'rejects a missing or malformed placeid' do
      get '/api/v1/places/place/details/json', headers: @auth_headers
      expect(response.status).to eq(400)

      get '/api/v1/places/place/details/json', params: { placeid: 'abc&fields=reviews' }, headers: @auth_headers
      expect(response.status).to eq(400)

      expect(Net::HTTP).not_to have_received(:start)
    end
  end
end
