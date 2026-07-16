require 'spec_helper'

describe Api::V1::LocationTypesController, type: :request do
  before(:each) do
    @user = FactoryBot.create(:user)
    @api_token = FactoryBot.create(:api_token, user: @user)
    @api_token.approve!(approved_by: @user)
  end

  describe 'when the api_token gate is disabled' do
    it 'allows the request through with no token or AppVersion header' do
      get '/api/v1/location_types.json'

      expect(response).to be_successful
    end
  end

  describe 'when the api_token gate is enabled' do
    before(:each) do
      allow(Api::V1::BaseController).to receive(:api_token_gate_enabled?).and_return(true)
    end

    it 'allows the request through when the AppVersion header is present, token or not' do
      get '/api/v1/location_types.json', headers: { 'AppVersion' => '1.0' }

      expect(response).to be_successful
    end

    it 'allows the request through with a valid active api_token param' do
      get '/api/v1/location_types.json', params: { api_token: @api_token.token }

      expect(response).to be_successful
    end

    it 'allows the request through with a valid active api_token via the X-Api-Token header' do
      get '/api/v1/location_types.json', headers: { 'X-Api-Token' => @api_token.token }

      expect(response).to be_successful
    end

    it 'rejects the request with no token and no AppVersion header' do
      get '/api/v1/location_types.json'

      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)['error']).to eq(Api::V1::BaseController::API_TOKEN_REQUIRED_MSG)
    end

    it 'rejects an unrecognized token' do
      get '/api/v1/location_types.json', params: { api_token: 'not-a-real-token' }

      expect(response).to have_http_status(:unauthorized)
    end

    it 'rejects a pending token' do
      pending_token = FactoryBot.create(:api_token, user: @user)

      get '/api/v1/location_types.json', params: { api_token: pending_token.token }

      expect(response).to have_http_status(:unauthorized)
    end

    it 'rejects a revoked token' do
      @api_token.revoke!(by: @user)

      get '/api/v1/location_types.json', params: { api_token: @api_token.token }

      expect(response).to have_http_status(:unauthorized)
    end

    it 'rejects a token belonging to a disabled user' do
      @user.update!(is_disabled: true)

      get '/api/v1/location_types.json', params: { api_token: @api_token.token }

      expect(response).to have_http_status(:unauthorized)
    end

    it 'exempts the tidbyt endpoint even with no token or AppVersion header' do
      region = FactoryBot.create(:region, lat: 10, lon: 10)
      location = FactoryBot.create(:location, region: region, lat: 10, lon: 10)

      get '/api/v1/location_machine_xrefs/most_recent_by_lat_lon.json', params: { lat: 10, lon: 10 }

      expect(response).to be_successful
    end
  end
end
