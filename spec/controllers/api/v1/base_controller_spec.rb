require 'spec_helper'

describe Api::V1::BaseController, type: :controller do
  controller do
    def index
      render json: { user_id: @api_token_user_id, key: api_token_rate_limit_key, exempt: token_exempt_from_rate_limit? }
    end
  end

  before(:each) do
    @user = FactoryBot.create(:user)
    @api_token = FactoryBot.create(:api_token, user: @user)
    @api_token.approve!(approved_by: @user)
  end

  describe '#api_token_rate_limit_key' do
    it 'falls back to the request ip when no token was resolved' do
      get :index

      body = JSON.parse(response.body)
      expect(body['user_id']).to be_nil
      expect(body['key']).to eq(request.remote_ip)
    end

    it 'keys by the resolved token user id once the gate has resolved a token' do
      controller.instance_variable_set(:@api_token_user_id, @user.id)

      get :index

      body = JSON.parse(response.body)
      expect(body['key']).to eq(@user.id)
    end
  end

  describe '#token_exempt_from_rate_limit?' do
    it 'is false when no token was resolved' do
      get :index

      expect(JSON.parse(response.body)['exempt']).to eq(false)
    end

    it 'is false for a resolved token that is not flagged exempt' do
      controller.instance_variable_set(:@resolved_api_token, @api_token)

      get :index

      expect(JSON.parse(response.body)['exempt']).to eq(false)
    end

    it 'is true for a resolved token flagged exempt_from_rate_limit' do
      @api_token.update!(exempt_from_rate_limit: true)
      controller.instance_variable_set(:@resolved_api_token, @api_token)

      get :index

      expect(JSON.parse(response.body)['exempt']).to eq(true)
    end
  end
end
