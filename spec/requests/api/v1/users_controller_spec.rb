require 'spec_helper'

describe Api::V1::UsersController, type: :request do
  describe '#auth_details' do
    before(:each) do
      @user = FactoryBot.create(:user, id: 1, username: 'ssw', email: 'yeah@ok.com', password: 'okokokok', password_confirmation: 'okokokok', authentication_token: 'abc123')
    end

    it 'returns all app-centric user data' do
      get '/api/v1/users/auth_details.json', params: { login: 'yeah@ok.com', password: 'okokokok' }

      expect(response).to be_successful
      expect(response.body).to include('ssw')
      expect(response.body).to include('yeah@ok.com')
      expect(response.body).to include('abc123')

      get '/api/v1/users/auth_details.json', params: { login: 'ssw', password: 'okokokok' }

      expect(response).to be_successful
      expect(response.body).to include('ssw')
      expect(response.body).to include('yeah@ok.com')
      expect(response.body).to include('abc123')
    end

    it 'handles username/email as case insensitive' do
      get '/api/v1/users/auth_details.json', params: { login: 'yEAh@ok.com', password: 'okokokok' }

      expect(response).to be_successful
      expect(response.body).to include('ssw')
      expect(response.body).to include('yeah@ok.com')
      expect(response.body).to include('abc123')

      get '/api/v1/users/auth_details.json', params: { login: 'sSW', password: 'okokokok' }

      expect(response).to be_successful
      expect(response.body).to include('ssw')
      expect(response.body).to include('yeah@ok.com')
      expect(response.body).to include('abc123')
    end

    it 'requires either username or user_email and password' do
      get '/api/v1/users/auth_details.json', params: { password: 'okokokok' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('login and password are required fields')

      get '/api/v1/users/auth_details.json', params: { login: 'ssw' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('login and password are required fields')
    end

    it 'tells you if your user is not confirmed' do
      FactoryBot.create(:user, id: 333, username: 'unconfirmed', password: 'okokokok', password_confirmation: 'okokokok', authentication_token: 'abc456', confirmed_at: nil)

      get '/api/v1/users/auth_details.json', params: { login: 'unconfirmed', password: 'okokokok' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('User is not yet confirmed. Please follow emailed confirmation instructions.')
    end

    it 'tells you if your user is disabled' do
      FactoryBot.create(:user, id: 334, username: 'disabled', password: 'okokokok', password_confirmation: 'okokokok', authentication_token: 'abc456', is_disabled: true)

      get '/api/v1/users/auth_details.json', params: { login: 'disabled', password: 'okokokok' }

      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)['error']).to eq('account_disabled')
    end

    it 'tells you if you enter the wrong password' do
      get '/api/v1/users/auth_details.json', params: { login: 'ssw', password: 'NOT_okokokok' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Incorrect password')
    end

    it 'tells you if this user does not exist' do
      get '/api/v1/users/auth_details.json', params: { login: 's', password: 'okokokok' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Unknown user')
    end
  end

  describe '#resend_confirmation' do
    it 'requires identification' do
      post '/api/v1/users/resend_confirmation.json'

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Please send an email or username to use this feature')
    end

    it 'works via username' do
      FactoryBot.create(:user, username: 'username')

      post '/api/v1/users/resend_confirmation.json', params: { identification: 'username' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['msg']).to eq('Confirmation info resent.')

      post '/api/v1/users/resend_confirmation.json', params: { identification: 'useRname' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['msg']).to eq('Confirmation info resent.')
    end

    it 'works via email' do
      FactoryBot.create(:user, email: 'yeah@ok.com')

      post '/api/v1/users/resend_confirmation.json', params: { identification: 'yeah@ok.com' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['msg']).to eq('Confirmation info resent.')
    end
  end

  describe '#forgot_password' do
    it 'requires identification' do
      post '/api/v1/users/forgot_password.json'

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Please send an email or username to use this feature')
    end

    it 'works via username' do
      FactoryBot.create(:user, username: 'username')

      post '/api/v1/users/forgot_password.json', params: { identification: 'username' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['msg']).to eq('Password reset request successful.')

      post '/api/v1/users/forgot_password.json', params: { identification: 'useRname' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['msg']).to eq('Password reset request successful.')
    end

    it 'works via email' do
      FactoryBot.create(:user, email: 'yeah@ok.com')

      post '/api/v1/users/forgot_password.json', params: { identification: 'yeah@ok.com' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['msg']).to eq('Password reset request successful.')
    end
  end

  describe '#signup' do
    it 'returns all app-centric user data if successful' do
      post '/api/v1/users/signup.json', params: { username: 'foo', email: 'yeah@ok.com', password: 'okokokok', confirm_password: 'okokokok' }

      expect(response).to be_successful
      expect(response.body).to include('foo')
      expect(response.body).to include('yeah@ok.com')
      expect(response.body).to include('authentication_token')
    end

    it 'requires a username and email address' do
      post '/api/v1/users/signup.json', params: { username: '', email: 'yeah@ok.com', password: 'okokokok', confirm_password: 'okokokok' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('username and email are required fields')

      post '/api/v1/users/signup.json', params: { username: 'yeah', email: '', password: 'okokokok', confirm_password: 'okokokok' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('username and email are required fields')
    end

    it 'does not allow blank passwords' do
      post '/api/v1/users/signup.json', params: { username: 'yeah', email: 'yeah@ok.com', password: '', confirm_password: '' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('password can not be blank')
    end

    it 'tells you if passwords do not match' do
      post '/api/v1/users/signup.json', params: { username: 'yeah', email: 'yeah@ok.com', password: 'okokokok', confirm_password: 'NOPE' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('your entered passwords do not match')
    end

    it 'does not allow duplicated usernames' do
      FactoryBot.create(:user, id: 1, username: 'ssw', email: 'yeah@ok.com', password: 'okokokok', password_confirmation: 'okokokok', authentication_token: 'abc123')

      post '/api/v1/users/signup.json', params: { username: 'ssw', email: 'yeah@ok.com', password: 'okokokok', confirm_password: 'okokokok' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('This username already exists')
    end

    it 'does not allow duplicated email addresses' do
      FactoryBot.create(:user, id: 1, username: 'ssw', email: 'yeah@ok.com', password: 'okokokok', password_confirmation: 'okokokok', authentication_token: 'abc123')

      post '/api/v1/users/signup.json', params: { username: 'CLEO', email: 'yeah@ok.com', password: 'okokokok', confirm_password: 'okokokok' }

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
      FactoryBot.create(:operator, id: 889, name: 'Craig T Pinball LLC')
      @user = FactoryBot.create(:user, id: 111, email: 'foo@bar.com', authentication_token: '1G8_s7P-V-4MGojaKD7a', username: 'ssw', created_at: '2016-01-01', admin_title: 'Administrator', contributor_rank: 'Magician', flag: 'us', operator_id: 889)
      location = FactoryBot.create(:location, id: 100, region_id: 1000, name: 'location')
      another_location = FactoryBot.create(:location, id: 101, region_id: 1001, name: 'another location')

      FactoryBot.create(:user_submission, user: @user, created_at: '2017-01-01', location: location, submission_type: UserSubmission::NEW_LMX_TYPE, location_name: 'location', location_id: 100)
      @user.update_column(:num_machines_added, 1)
      FactoryBot.create(:user_submission, user: @user, created_at: '2017-01-01', location: location, submission_type: UserSubmission::REMOVE_MACHINE_TYPE, location_name: 'location', location_id: 100)
      @user.update_column(:num_machines_removed, 1)
      FactoryBot.create(:user_submission, user: @user, created_at: '2017-01-01', location: location, submission_type: UserSubmission::REMOVE_MACHINE_TYPE, location_name: 'location', location_id: 100)
      @user.update_column(:num_machines_removed, 2)
      FactoryBot.create(:user_submission, user: @user, created_at: '2017-01-01', location: location, submission_type: UserSubmission::NEW_CONDITION_TYPE, location_name: 'location', location_id: 100)
      @user.update_column(:num_lmx_comments_left, 1)
      FactoryBot.create(:user_submission, user: @user, created_at: '2017-01-01', location: location, submission_type: UserSubmission::NEW_CONDITION_TYPE, location_name: 'location', location_id: 100)
      @user.update_column(:num_lmx_comments_left, 2)
      FactoryBot.create(:user_submission, user: @user, created_at: '2017-01-02', location: another_location, submission_type: UserSubmission::NEW_CONDITION_TYPE, location_name: 'another location', location_id: 101)
      @user.update_column(:num_lmx_comments_left, 3)
      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::SUGGEST_LOCATION_TYPE)
      @user.update_column(:num_locations_suggested, 1)
      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::SUGGEST_LOCATION_TYPE)
      @user.update_column(:num_locations_suggested, 2)
      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::SUGGEST_LOCATION_TYPE)
      @user.update_column(:num_locations_suggested, 3)
      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::SUGGEST_LOCATION_TYPE)
      @user.update_column(:num_locations_suggested, 4)

      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::NEW_SCORE_TYPE, created_at: '2016-01-01', submission: 'ssw added a high score of 1234 on Cheetah at Bottles in Portland', location_name: 'location', location_id: 100)
      @user.update_column(:num_msx_scores_added, 1)
      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::NEW_SCORE_TYPE, created_at: '2016-01-02', submission: 'ssw added a high score of 12 on Machine at Location in Portland', location_name: 'location', location_id: 100)
      @user.update_column(:num_msx_scores_added, 2)
      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::NEW_SCORE_TYPE, created_at: '2016-01-02', submission: 'ssw added a high score of 14 on Machine at Location in Portland', location_name: 'location', location_id: 100)
      @user.update_column(:num_msx_scores_added, 3)

      machine = FactoryBot.create(:machine, name: 'Sass')
      lmx = FactoryBot.create(:location_machine_xref, machine_id: machine.id, location_id: location.id)
      machine2 = FactoryBot.create(:machine, name: 'Yoyo')
      lmx2 = FactoryBot.create(:location_machine_xref, machine_id: machine2.id, location_id: location.id)

      FactoryBot.create(:machine_score_xref, location_machine_xref: lmx, location: location, machine_id: lmx.machine_id, user: @user, score: 4000)
      FactoryBot.create(:machine_score_xref, location_machine_xref: lmx, location: location, machine_id: lmx.machine_id, user: @user, score: 5000)
      FactoryBot.create(:machine_score_xref, location_machine_xref: lmx2, location: location, machine_id: lmx2.machine_id, user: @user, score: 5500)
      FactoryBot.create(:machine_score_xref, location_machine_xref: lmx, location: location, machine_id: lmx.machine_id, user: FactoryBot.create(:user, id: 3334, email: 'yeahb@ok.com', authentication_token: '345', username: 'bert'), score: 7000)
    end

    it 'returns all profile stats for a given user' do
      get '/api/v1/users/111/profile_info.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }

      expect(response).to be_successful
      json = JSON.parse(response.body)['profile_info']

      expect(json['num_machines_added']).to eq(1)
      expect(json['num_machines_removed']).to eq(2)
      expect(json['num_lmx_comments_left']).to eq(3)
      expect(json['num_msx_scores_added']).to eq(3)
      expect(json['num_locations_suggested']).to eq(4)
      expect(json['num_locations_edited']).to eq(2)
      expect(json['admin_title']).to eq('Administrator')
      expect(json['contributor_rank']).to eq('Magician')
      expect(json['flag']).to eq('us')
      expect(json['operator_name']).to eq('Craig T Pinball LLC')
      expect(json['created_at']).to eq('2016-01-01T00:00:00.000-08:00')
      expect(json['profile_list_of_edited_locations']).to eq([
        [ 101, 'another location' ],
        [ 100, 'location' ]
      ])
      expect(json['profile_list_of_high_scores']).to eq([
        [ 'Location in Portland', 'Machine', '14', 'Jan 02, 2016' ],
        [ 'Bottles in Portland', 'Cheetah', '1,234', 'Jan 01, 2016' ]
      ])
      expect(json['profile_machine_scores_stats']).to include(hash_including("list" => [ 5000, 4000 ]))
      expect(json['profile_machine_scores_stats']).to include(hash_including("average" => 5500))
      expect(json['profile_machine_scores_stats']).to include(hash_including("count" => 2))
      expect(json['profile_machine_scores_stats']).to include(hash_including("list" =>  [ 5500 ]))
      expect(json['profile_machine_scores_stats']).to_not include(hash_including("list" => [ 7000 ]))
    end

    it 'tells you if this user does not exist' do
      get '/api/v1/users/-1/profile_info.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Failed to find user')
    end

    it 'excludes profile_list_of_high_scores when using the new_score_list_only flag' do
      get '/api/v1/users/111/profile_info.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', new_score_list_only: 1 }

      expect(response).to be_successful
      json = JSON.parse(response.body)['profile_info']

      expect(json).to include('profile_machine_scores_stats')
      expect(json).to_not include('profile_list_of_high_scores')
    end
  end
  describe '#update_email' do
    before(:each) do
      @user = FactoryBot.create(:user, id: 111, email: 'foo@bar.com', authentication_token: '1G8_s7P-V-4MGojaKD7a', username: 'ssw')
    end

    it 'updates the email address' do
      post '/api/v1/users/111/update_email.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', email: 'new@email.com' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['msg']).to eq('Email updated.')
      expect(@user.reload.email).to eq('new@email.com')
    end

    it 'does not let you update another user email' do
      FactoryBot.create(:user, id: 222, username: 'other', email: 'other@email.com')

      post '/api/v1/users/222/update_email.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', email: 'hacked@email.com' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Unauthorized user update.')
      expect(User.find(222).email).to eq('other@email.com')
    end

    it 'does not allow a blank email' do
      post '/api/v1/users/111/update_email.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', email: '' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Email can not be blank')
    end

    it 'does not allow a duplicate email' do
      FactoryBot.create(:user, id: 222, username: 'other', email: 'taken@email.com')

      post '/api/v1/users/111/update_email.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', email: 'taken@email.com' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to include('Email')
      expect(@user.reload.email).to eq('foo@bar.com')
    end

    it 'tells you if this user does not exist' do
      post '/api/v1/users/999/update_email.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', email: 'new@email.com' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Unknown user')
    end
  end

  describe '#update_password' do
    before(:each) do
      @user = FactoryBot.create(:user, id: 111, email: 'foo@bar.com', authentication_token: '1G8_s7P-V-4MGojaKD7a', username: 'ssw', password: 'oldpassword', password_confirmation: 'oldpassword')
    end

    it 'updates the password' do
      post '/api/v1/users/111/update_password.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', current_password: 'oldpassword', password: 'newpassword', password_confirmation: 'newpassword' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['msg']).to eq('Password updated.')
      expect(@user.reload.valid_password?('newpassword')).to be true
    end

    it 'does not let you update another user password' do
      FactoryBot.create(:user, id: 222, username: 'other', email: 'other@email.com', password: 'otherpassword', password_confirmation: 'otherpassword')

      post '/api/v1/users/222/update_password.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', current_password: 'oldpassword', password: 'newpassword', password_confirmation: 'newpassword' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Unauthorized user update.')
      expect(User.find(222).valid_password?('otherpassword')).to be true
    end

    it 'requires the correct current password' do
      post '/api/v1/users/111/update_password.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', current_password: 'wrongpassword', password: 'newpassword', password_confirmation: 'newpassword' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to include('Current password')
      expect(@user.reload.valid_password?('oldpassword')).to be true
    end

    it 'requires password and confirmation to match' do
      post '/api/v1/users/111/update_password.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', current_password: 'oldpassword', password: 'newpassword', password_confirmation: 'different' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to include("Password confirmation doesn't match")
      expect(@user.reload.valid_password?('oldpassword')).to be true
    end

    it 'tells you if this user does not exist' do
      post '/api/v1/users/999/update_password.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', current_password: 'oldpassword', password: 'newpassword', password_confirmation: 'newpassword' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Unknown user')
    end
  end

  describe '#destroy' do
    before(:each) do
      @user = FactoryBot.create(:user, id: 111, email: 'foo@bar.com', authentication_token: '1G8_s7P-V-4MGojaKD7a', username: 'ssw')
    end

    it 'deletes the user' do
      delete '/api/v1/users/111.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['msg']).to eq('User deleted.')
      expect(User.exists?(111)).to be false
    end

    it 'does not let you delete another user' do
      FactoryBot.create(:user, id: 222, username: 'other')

      delete '/api/v1/users/222.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Unauthorized user update.')
      expect(User.exists?(222)).to be true
    end

    it 'tells you if this user does not exist' do
      delete '/api/v1/users/999.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Unknown user')
    end
  end

  describe '#total_user_count' do
    it 'returns a count of all users' do
      FactoryBot.create(:user, id: 1)
      FactoryBot.create(:user, id: 2)
      get '/api/v1/users/total_user_count.json'

      expect(response).to be_successful
      expect(JSON.parse(response.body)['total_user_count']).to eq(2)
    end
  end
  describe '#update_user_flag' do
    before(:each) do
      FactoryBot.create(:user, id: 111, email: 'foo@bar.com', authentication_token: '1G8_s7P-V-4MGojaKD7a', username: 'ssw')
    end
    it 'updates your user flag field' do
      post '/api/v1/users/111/update_user_flag.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', flag: 'us-ca' }

      expect(response).to be_successful
      expect(response.body).to_not include('error')
      expect(response.body).to include('us-ca')
    end

    it 'does not let you do this for other users' do
      post '/api/v1/users/777/update_user_flag.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', flag: 'us-ca' }

      expect(response).to be_successful
      expect(response.body).to_not include('us-ca')
      expect(response.body).to include('error')
    end

    it 'does not let you save a value not in the list' do
      post '/api/v1/users/111/update_user_flag.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', flag: 'yyy' }

      expect(response).to be_successful
      expect(response.body).to_not include('yyy')
      expect(response.body).to include('error')
    end
  end
end
