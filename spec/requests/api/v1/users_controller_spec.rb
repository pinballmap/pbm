require 'spec_helper'

describe Api::V1::UsersController, type: :request do
  before(:each) do
    FactoryGirl.create(:user, id: 1, username: 'ssw', email: 'yeah@ok.com', password: 'okokok', password_confirmation: 'okokok', authentication_token: 'abc123')
  end

  describe '#auth_details' do
    it 'returns all app-centric user data' do
      get '/api/v1/users/auth_details.json', user_email: 'yeah@ok.com', password: 'okokok'

      expect(response).to be_success
      expect(response.body).to include('ssw')
      expect(response.body).to include('yeah@ok.com')
      expect(response.body).to include('abc123')

      get '/api/v1/users/auth_details.json', username: 'ssw', password: 'okokok'

      expect(response).to be_success
      expect(response.body).to include('ssw')
      expect(response.body).to include('yeah@ok.com')
      expect(response.body).to include('abc123')
    end

    it 'requires either username or user_email and password' do
      get '/api/v1/users/auth_details.json', password: 'okokok'

      expect(response).to be_success
      expect(JSON.parse(response.body)['errors']).to eq('(username or user_email) and password are required fields')

      get '/api/v1/users/auth_details.json', username: 'ssw'

      expect(response).to be_success
      expect(JSON.parse(response.body)['errors']).to eq('(username or user_email) and password are required fields')
    end

    it 'tells you if you enter the wrong password' do
      get '/api/v1/users/auth_details.json', username: 'ssw', password: 'NOT_okokok'

      expect(response).to be_success
      expect(JSON.parse(response.body)['errors']).to eq('Incorrect password')
    end

    it 'tells you if this user does not exist' do
      get '/api/v1/users/auth_details.json', username: 's', password: 'okokok'

      expect(response).to be_success
      expect(JSON.parse(response.body)['errors']).to eq('Unknown user')
    end
  end
end
