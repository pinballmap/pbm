require 'spec_helper'

describe Api::V1::UsersController, type: :request do
  describe '#auth_details' do
    before(:each) do
      @user = FactoryBot.create(:user, id: 1, username: 'ssw', email: 'yeah@ok.com', password: 'okokok', password_confirmation: 'okokok', authentication_token: 'abc123')
    end

    it 'returns all app-centric user data' do
      get '/api/v1/users/auth_details.json', params: { login: 'yeah@ok.com', password: 'okokok' }

      expect(response).to be_successful
      expect(response.body).to include('ssw')
      expect(response.body).to include('yeah@ok.com')
      expect(response.body).to include('abc123')

      get '/api/v1/users/auth_details.json', params: { login: 'ssw', password: 'okokok' }

      expect(response).to be_successful
      expect(response.body).to include('ssw')
      expect(response.body).to include('yeah@ok.com')
      expect(response.body).to include('abc123')
    end

    it 'handles username/email as case insensitive' do
      get '/api/v1/users/auth_details.json', params: { login: 'yEAh@ok.com', password: 'okokok' }

      expect(response).to be_successful
      expect(response.body).to include('ssw')
      expect(response.body).to include('yeah@ok.com')
      expect(response.body).to include('abc123')

      get '/api/v1/users/auth_details.json', params: { login: 'sSW', password: 'okokok' }

      expect(response).to be_successful
      expect(response.body).to include('ssw')
      expect(response.body).to include('yeah@ok.com')
      expect(response.body).to include('abc123')
    end

    it 'requires either username or user_email and password' do
      get '/api/v1/users/auth_details.json', params: { password: 'okokok' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('login and password are required fields')

      get '/api/v1/users/auth_details.json', params: { login: 'ssw' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('login and password are required fields')
    end

    it 'tells you if your user is not confirmed' do
      FactoryBot.create(:user, id: 333, username: 'unconfirmed', password: 'okokok', password_confirmation: 'okokok', authentication_token: 'abc456', confirmed_at: nil)

      get '/api/v1/users/auth_details.json', params: { login: 'unconfirmed', password: 'okokok' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('User is not yet confirmed. Please follow emailed confirmation instructions.')
    end

    it 'tells you if your user is disabled' do
      FactoryBot.create(:user, id: 334, username: 'disabled', password: 'okokok', password_confirmation: 'okokok', authentication_token: 'abc456', is_disabled: true)

      get '/api/v1/users/auth_details.json', params: { login: 'disabled', password: 'okokok' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Your account is disabled. Please contact us if you think this is a mistake.')
    end

    it 'tells you if you enter the wrong password' do
      get '/api/v1/users/auth_details.json', params: { login: 'ssw', password: 'NOT_okokok' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Incorrect password')
    end

    it 'tells you if this user does not exist' do
      get '/api/v1/users/auth_details.json', params: { login: 's', password: 'okokok' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Unknown user')
    end
  end

  describe '#signup' do
    it 'returns all app-centric user data if successful' do
      post '/api/v1/users/signup.json', params: { username: 'foo', email: 'yeah@ok.com', password: 'okokok', confirm_password: 'okokok' }

      expect(response).to be_successful
      expect(response.body).to include('foo')
      expect(response.body).to include('yeah@ok.com')
      expect(response.body).to include('authentication_token')
    end

    it 'requires a username and email address' do
      post '/api/v1/users/signup.json', params: { username: '', email: 'yeah@ok.com', password: 'okokok', confirm_password: 'okokok' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('username and email are required fields')

      post '/api/v1/users/signup.json', params: { username: 'yeah', email: '', password: 'okokok', confirm_password: 'okokok' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('username and email are required fields')
    end

    it 'does not allow blank passwords' do
      post '/api/v1/users/signup.json', params: { username: 'yeah', email: 'yeah@ok.com', password: '', confirm_password: '' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('password can not be blank')
    end

    it 'tells you if passwords do not match' do
      post '/api/v1/users/signup.json', params: { username: 'yeah', email: 'yeah@ok.com', password: 'okokok', confirm_password: 'NOPE' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('your entered passwords do not match')
    end

    it 'does not allow duplicated usernames' do
      FactoryBot.create(:user, id: 1, username: 'ssw', email: 'yeah@ok.com', password: 'okokok', password_confirmation: 'okokok', authentication_token: 'abc123')

      post '/api/v1/users/signup.json', params: { username: 'ssw', email: 'yeah@ok.com', password: 'okokok', confirm_password: 'okokok' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('This username already exists')
    end

    it 'does not allow duplicated email addresses' do
      FactoryBot.create(:user, id: 1, username: 'ssw', email: 'yeah@ok.com', password: 'okokok', password_confirmation: 'okokok', authentication_token: 'abc123')

      post '/api/v1/users/signup.json', params: { username: 'CLEO', email: 'yeah@ok.com', password: 'okokok', confirm_password: 'okokok' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('This email address already exists')
    end
  end

  describe '#add_fave_location' do
    it 'adds a location to your list of favorites' do
      user = FactoryBot.create(:user, id: 111, email: 'foo@bar.com', authentication_token: '1G8_s7P-V-4MGojaKD7a', username: 'ssw')

      new_location = FactoryBot.create(:location, id: 555)

      expect(UserFaveLocation.all.count).to eq(0)

      post '/api/v1/users/111/add_fave_location.json', params: { location_id: 555, user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }

      expect(UserFaveLocation.first.user_id).to eq(user.id)
      expect(UserFaveLocation.first.location_id).to eq(new_location.id)
    end

    it 'rejects duplicate attempts to add' do
      FactoryBot.create(:user, id: 111, email: 'foo@bar.com', authentication_token: '1G8_s7P-V-4MGojaKD7a', username: 'ssw')
      FactoryBot.create(:location, id: 555)

      post '/api/v1/users/111/add_fave_location.json', params: { location_id: 555, user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }

      expect(UserFaveLocation.all.size).to eq(1)

      post '/api/v1/users/111/add_fave_location.json', params: { location_id: 555, user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('This location is already saved as a fave.')
      expect(UserFaveLocation.all.size).to eq(1)
    end

    it 'does not let you do this for other users' do
      FactoryBot.create(:user, id: 111, email: 'foo@bar.com', authentication_token: '1G8_s7P-V-4MGojaKD7a', username: 'ssw')
      FactoryBot.create(:user, id: 112)

      FactoryBot.create(:location, id: 555)

      expect(UserFaveLocation.all.count).to eq(0)

      post '/api/v1/users/112/add_fave_location.json', params: { location_id: 555, user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Unauthorized user update.')
      expect(UserFaveLocation.all.count).to eq(0)
    end

    it 'tells you if this user does not exist' do
      post '/api/v1/users/234/add_fave_location.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Unknown asset')
    end

    it 'tells you if this location does not exist' do
      post '/api/v1/users/111/add_fave_location.json', params: { location_id: 999, user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Unknown asset')
    end
  end

  describe '#remove_fave_location' do
    it 'removes a location to your list of favorites' do
      user = FactoryBot.create(:user, id: 111, email: 'foo@bar.com', authentication_token: '1G8_s7P-V-4MGojaKD7a', username: 'ssw')

      FactoryBot.create(:user_fave_location, user: user, location: FactoryBot.create(:location, id: 123))
      FactoryBot.create(:user_fave_location, user: user, location: FactoryBot.create(:location, id: 456))

      post '/api/v1/users/111/remove_fave_location.json', params: { location_id: 123, user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }

      expect(UserFaveLocation.all.count).to eq(1)
      expect(UserFaveLocation.first.user_id).to eq(user.id)
      expect(UserFaveLocation.first.location_id).to eq(456)
    end

    it 'does not let you do this for other users' do
      FactoryBot.create(:user, id: 111, email: 'foo@bar.com', authentication_token: '1G8_s7P-V-4MGojaKD7a', username: 'ssw')

      FactoryBot.create(:user_fave_location, user: FactoryBot.create(:user, id: 777), location: FactoryBot.create(:location, id: 123))

      post '/api/v1/users/777/remove_fave_location.json', params: { location_id: 123, user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }

      expect(UserFaveLocation.all.count).to eq(1)
    end

    it 'tells you if this user does not exist' do
      post '/api/v1/users/234/remove_fave_location.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Unknown asset')
    end

    it 'tells you if this location does not exist' do
      post '/api/v1/users/111/remove_fave_location.json', params: { location_id: 999, user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Unknown asset')
    end
  end

  describe '#list_fave_locations' do
    it 'sends all favorited locations for a user' do
      user = FactoryBot.create(:user, id: 111, email: 'foo@bar.com', authentication_token: '1G8_s7P-V-4MGojaKD7a', username: 'ssw')

      location = FactoryBot.create(:location, id: 123)
      FactoryBot.create(:user_fave_location, user: user, location: location)
      FactoryBot.create(:location_machine_xref, location: location)
      FactoryBot.create(:user_fave_location, user: user, location: FactoryBot.create(:location, id: 456))

      FactoryBot.create(:user_fave_location, user: FactoryBot.create(:user), location: FactoryBot.create(:location, id: 789))

      get '/api/v1/users/111/list_fave_locations.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }

      expect(response).to be_successful
      json = JSON.parse(response.body)['user_fave_locations']

      expect(json.count).to eq(2)
      expect(json[0]['location_id']).to eq(123)
      expect(json[0]['location']['location_type']['name']).to eq('Test Location Type')
      expect(json[0]['location']['machines'][0]['name']).to eq('Test Machine Name')
      expect(json[1]['location_id']).to eq(456)
    end

    it 'tells you if this user does not exist' do
      get '/api/v1/users/234/list_fave_locations.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Unknown user')
    end
  end

  describe '#profile_info' do
    before(:each) do
      @user = FactoryBot.create(:user, id: 111, email: 'foo@bar.com', authentication_token: '1G8_s7P-V-4MGojaKD7a', username: 'ssw', created_at: '2016-01-01')
    end

    it 'returns all profile stats for a given user' do
      location = FactoryBot.create(:location, id: 100, region_id: 1000, name: 'location')
      another_location = FactoryBot.create(:location, id: 101, region_id: 1001, name: 'another location')

      FactoryBot.create(:user_submission, user: @user, created_at: '2017-01-01', location: location, submission_type: UserSubmission::NEW_LMX_TYPE)
      FactoryBot.create(:user_submission, user: @user, created_at: '2017-01-01', location: location, submission_type: UserSubmission::REMOVE_MACHINE_TYPE)
      FactoryBot.create(:user_submission, user: @user, created_at: '2017-01-01', location: location, submission_type: UserSubmission::REMOVE_MACHINE_TYPE)
      FactoryBot.create(:user_submission, user: @user, created_at: '2017-01-01', location: location, submission_type: UserSubmission::NEW_CONDITION_TYPE)
      FactoryBot.create(:user_submission, user: @user, created_at: '2017-01-01', location: location, submission_type: UserSubmission::NEW_CONDITION_TYPE)
      FactoryBot.create(:user_submission, user: @user, created_at: '2017-01-02', location: another_location, submission_type: UserSubmission::NEW_CONDITION_TYPE)
      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::SUGGEST_LOCATION_TYPE)
      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::SUGGEST_LOCATION_TYPE)
      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::SUGGEST_LOCATION_TYPE)
      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::SUGGEST_LOCATION_TYPE)

      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::NEW_SCORE_TYPE, created_at: '2016-01-01', submission: 'User ssw (scott.wainstock@gmail.com) added a score of 1234 for Cheetah to Bottles')
      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::NEW_SCORE_TYPE, created_at: '2016-01-02', submission: 'User ssw (scott.wainstock@gmail.com) added a score of 12 for Machine to Location')

      get '/api/v1/users/111/profile_info.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }

      expect(response).to be_successful
      json = JSON.parse(response.body)['profile_info']

      expect(json['num_machines_added']).to eq(1)
      expect(json['num_machines_removed']).to eq(2)
      expect(json['num_lmx_comments_left']).to eq(3)
      expect(json['num_locations_suggested']).to eq(4)
      expect(json['num_locations_edited']).to eq(2)
      expect(json['created_at']).to eq('2016-01-01T00:00:00.000Z')
      expect(json['profile_list_of_edited_locations']).to eq([
        [101, 'another location', 1001],
        [100, 'location', 1000]
      ])
      expect(json['profile_list_of_high_scores']).to eq([
        ['Location', 'Machine', '12', 'Jan-02-2016'],
        ['Bottles', 'Cheetah', '1,234', 'Jan-01-2016']
      ])
    end

    it 'tells you if this user does not exist' do
      get '/api/v1/users/-1/profile_info.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Failed to find user')
    end
  end
end
