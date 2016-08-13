require 'spec_helper'

describe Api::V1::UsersController, type: :request do
  describe '#auth_details' do
    before(:each) do
      FactoryGirl.create(:user, id: 1, username: 'ssw', email: 'yeah@ok.com', password: 'okokok', password_confirmation: 'okokok', authentication_token: 'abc123')
    end

    it 'returns all app-centric user data' do
      get '/api/v1/users/auth_details.json', login: 'yeah@ok.com', password: 'okokok'

      expect(response).to be_success
      expect(response.body).to include('ssw')
      expect(response.body).to include('yeah@ok.com')
      expect(response.body).to include('abc123')

      get '/api/v1/users/auth_details.json', login: 'ssw', password: 'okokok'

      expect(response).to be_success
      expect(response.body).to include('ssw')
      expect(response.body).to include('yeah@ok.com')
      expect(response.body).to include('abc123')
    end

    it 'requires either username or user_email and password' do
      get '/api/v1/users/auth_details.json', password: 'okokok'

      expect(response).to be_success
      expect(JSON.parse(response.body)['errors']).to eq('login and password are required fields')

      get '/api/v1/users/auth_details.json', login: 'ssw'

      expect(response).to be_success
      expect(JSON.parse(response.body)['errors']).to eq('login and password are required fields')
    end

    it 'tells you if you enter the wrong password' do
      get '/api/v1/users/auth_details.json', login: 'ssw', password: 'NOT_okokok'

      expect(response).to be_success
      expect(JSON.parse(response.body)['errors']).to eq('Incorrect password')
    end

    it 'tells you if this user does not exist' do
      get '/api/v1/users/auth_details.json', login: 's', password: 'okokok'

      expect(response).to be_success
      expect(JSON.parse(response.body)['errors']).to eq('Unknown user')
    end
  end

  describe '#signup' do
    it 'returns all app-centric user data if successful' do
      post '/api/v1/users/signup.json', username: 'foo', email: 'yeah@ok.com', password: 'okokok', confirm_password: 'okokok'

      expect(response).to be_success
      expect(response.body).to include('foo')
      expect(response.body).to include('yeah@ok.com')
      expect(response.body).to include('authentication_token')
    end

    it 'requires a username and email address' do
      post '/api/v1/users/signup.json', username: '', email: 'yeah@ok.com', password: 'okokok', confirm_password: 'okokok'

      expect(response).to be_success
      expect(JSON.parse(response.body)['errors']).to eq('username and email are required fields')

      post '/api/v1/users/signup.json', username: 'yeah', email: '', password: 'okokok', confirm_password: 'okokok'

      expect(response).to be_success
      expect(JSON.parse(response.body)['errors']).to eq('username and email are required fields')
    end

    it 'does not allow blank passwords' do
      post '/api/v1/users/signup.json', username: 'yeah', email: 'yeah@ok.com', password: '', confirm_password: ''

      expect(response).to be_success
      expect(JSON.parse(response.body)['errors']).to eq('password can not be blank')
    end

    it 'tells you if passwords do not match' do
      post '/api/v1/users/signup.json', username: 'yeah', email: 'yeah@ok.com', password: 'okokok', confirm_password: 'NOPE'

      expect(response).to be_success
      expect(JSON.parse(response.body)['errors']).to eq('your entered passwords do not match')
    end

    it 'does not allow duplicated usernames' do
      FactoryGirl.create(:user, id: 1, username: 'ssw', email: 'yeah@ok.com', password: 'okokok', password_confirmation: 'okokok', authentication_token: 'abc123')

      post '/api/v1/users/signup.json', username: 'ssw', email: 'yeah@ok.com', password: 'okokok', confirm_password: 'okokok'

      expect(response).to be_success
      expect(JSON.parse(response.body)['errors']).to eq('This username already exists')
    end

    it 'does not allow duplicated email addresses' do
      FactoryGirl.create(:user, id: 1, username: 'ssw', email: 'yeah@ok.com', password: 'okokok', password_confirmation: 'okokok', authentication_token: 'abc123')

      post '/api/v1/users/signup.json', username: 'CLEO', email: 'yeah@ok.com', password: 'okokok', confirm_password: 'okokok'

      expect(response).to be_success
      expect(JSON.parse(response.body)['errors']).to eq('This email address already exists')
    end
  end
end
