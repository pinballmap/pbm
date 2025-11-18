require 'spec_helper'

describe Api::V1::MachineScoreXrefsController, type: :request do
  before(:each) do
    @region = FactoryBot.create(:region, name: 'portland', should_email_machine_removal: 0)
    @location = FactoryBot.create(:location, name: 'Ground Kontrol', region: @region)
    @machine = FactoryBot.create(:machine, name: 'Cleo')
    @lmx = FactoryBot.create(:location_machine_xref, machine_id: @machine.id, location_id: @location.id)

    @score_one = FactoryBot.create(:machine_score_xref, location_machine_xref: @lmx, score: 123, user_id: FactoryBot.create(:user, id: 333, username: 'ssw').id)
    @score_two = FactoryBot.create(:machine_score_xref, location_machine_xref: @lmx, score: 100, user_id: nil)
    @user = FactoryBot.create(:user, id: 111, email: 'foo@bar.com', authentication_token: '1G8_s7P-V-4MGojaKD7a', username: 'cibw')
  end

  describe '#index' do
    it 'shows all scores for region' do
      chicago = FactoryBot.create(:region, name: 'Chicago')
      chicago_location = FactoryBot.create(:location, name: 'Barb', region: chicago)
      chicago_lmx = FactoryBot.create(:location_machine_xref, location: chicago_location, machine: @machine)
      FactoryBot.create(:machine_score_xref, location_machine_xref: chicago_lmx, score: 567)

      get '/api/v1/region/portland/machine_score_xrefs.json'
      expect(response).to be_successful

      scores = JSON.parse(response.body)['machine_score_xrefs']

      expect(scores.size).to eq(2)
    end

    it 'respects limit scope' do
      get '/api/v1/region/portland/machine_score_xrefs.json', params: { limit: 1 }
      expect(response).to be_successful

      scores = JSON.parse(response.body)['machine_score_xrefs']

      expect(scores.size).to eq(1)
    end

    it 'respects zone_id scope' do
      FactoryBot.create(:zone, id: 1, region: @region)
      FactoryBot.create(:zone, id: 2, region: @region)

      3.times do
        FactoryBot.create(:machine_score_xref, location_machine_xref: FactoryBot.create(:location_machine_xref, location: FactoryBot.create(:location, region: @region, zone_id: 1)), score: 100)
      end

      FactoryBot.create(:machine_score_xref, location_machine_xref: FactoryBot.create(:location_machine_xref, location: FactoryBot.create(:location, region: @region, zone_id: 2)), score: 100)

      get '/api/v1/region/portland/machine_score_xrefs.json', params: { zone_id: 1 }
      expect(response).to be_successful

      scores = JSON.parse(response.body)['machine_score_xrefs']

      expect(scores.size).to eq(3)
    end
  end

  describe '#show' do
    it 'shows all scores for lmx' do
      get '/api/v1/machine_score_xrefs/' + @lmx.id.to_s + '.json'
      expect(response).to be_successful

      scores = JSON.parse(response.body)['machine_scores']

      expect(scores.size).to eq(2)

      expect(scores[0]['score']).to eq(123)
      expect(scores[0]['username']).to eq('ssw')

      expect(scores[1]['score']).to eq(100)
      expect(scores[1]['username']).to eq('')
    end

    it 'errors for unknown lmx' do
      get '/api/v1/machine_score_xrefs/-1.json'
      expect(response).to be_successful

      expect(JSON.parse(response.body)['errors']).to eq('Failed to find machine')
    end
  end

  describe '#create' do
    it 'errors for unknown lmx' do
      post '/api/v1/machine_score_xrefs.json', params: { location_machine_xref_id: -1, score: 1234, user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful

      expect(JSON.parse(response.body)['errors']).to eq('Failed to find machine')
    end

    it 'errors for blank scores' do
      post '/api/v1/machine_score_xrefs.json', params: { location_machine_xref_id: @lmx.id.to_s, user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful

      expect(JSON.parse(response.body)['errors']).to eq('Score can not be blank and must be a numeric value')
    end

    it 'errors when numbers are larger than bigints (>9223372036854775807)' do
      post '/api/v1/machine_score_xrefs.json', params: { location_machine_xref_id: @lmx.id.to_s, score: 9_223_372_036_854_775_808, user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful

      expect(JSON.parse(response.body)['errors']).to eq('Number is too large. Please enter a valid score.')
    end

    it 'return an error if you enter a non-integer score' do
      post '/api/v1/machine_score_xrefs.json', params: { location_machine_xref_id: @lmx.id.to_s, score: 'fword', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful

      expect(JSON.parse(response.body)['errors']).to eq('Score can not be blank and must be a numeric value')
    end

    it 'errors when not authed' do
      post '/api/v1/machine_score_xrefs.json', params: { location_machine_xref_id: @lmx.id.to_s, score: 1234 }
      expect(response).to be_successful

      expect(JSON.parse(response.body)['errors']).to eq(Api::V1::MachineScoreXrefsController::AUTH_REQUIRED_MSG)
    end

    it 'creates a new score -- authed' do
      post '/api/v1/machine_score_xrefs.json', params: { location_machine_xref_id: @lmx.id.to_s, score: 1234, user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }
      expect(response).to be_successful
      expect(response.status).to eq(201)

      expect(JSON.parse(response.body)['machine_score_xref']['score']).to eq(1234)

      new_score = MachineScoreXref.last

      expect(new_score.score).to eq(1234)
      expect(new_score.location_machine_xref_id).to eq(@lmx.id)
      expect(new_score.user_id).to eq(@user.id)

      first_score = MachineScoreXref.first
      expect(first_score.score).to eq(123)

      submission = UserSubmission.last

      expect(submission.location).to eq(@lmx.location)
      expect(submission.machine).to eq(@lmx.machine)
      expect(submission.user.id).to eq(111)
      expect(submission.submission_type).to eq(UserSubmission::NEW_SCORE_TYPE)
      expect(submission.submission).to eq('cibw added a high score of 1,234 on Cleo at Ground Kontrol in Portland')
    end
  end

  describe '#destroy' do
    it 'notifies you when it can not find a high score' do
      delete '/api/v1/machine_score_xrefs/1234.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Failed to find high score')
    end

    it 'deletes when you own the high score' do
      owned_high_score = FactoryBot.create(:machine_score_xref, user: @user, id: 56)
      FactoryBot.create(:user_submission, created_at: '2025-01-01', submission_type: UserSubmission::NEW_SCORE_TYPE, machine_score_xref_id: 56)

      delete '/api/v1/machine_score_xrefs/' + owned_high_score.id.to_s + '.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['high_score']).to eq('Successfully removed high score')
      expect(MachineScoreXref.all.size).to eq(2)
      expect(UserSubmission.last.deleted_at).to_not eq(nil)
    end

    it 'does not delete when you do not own the high score' do
      @evil_user = FactoryBot.create(:user, id: 222, email: 'yeah@ok.com', authentication_token: '123', username: 'sass')
      owned_high_score = FactoryBot.create(:machine_score_xref, user: @user)

      delete '/api/v1/machine_score_xrefs/' + owned_high_score.id.to_s + '.json', params: { user_email: 'yeah@ok.com', user_token: '123' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('You can only delete high scores that you own')
      expect(MachineScoreXref.all.size).to eq(3)
    end
  end

  describe '#update' do
    it 'notifies you when it can not find a high score' do
      put '/api/v1/machine_score_xrefs/123.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', score: 200 }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Failed to find high score')
    end

    it 'updates when you own the high score' do
      owned_high_score = FactoryBot.create(:machine_score_xref, user: @user, score: 100, id: 57)
      FactoryBot.create(:user_submission, created_at: '2025-01-01', submission_type: UserSubmission::NEW_SCORE_TYPE, high_score: 100, machine_score_xref_id: 57)

      put '/api/v1/machine_score_xrefs/' + owned_high_score.id.to_s + '.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', score: 200 }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['high_score']).to eq('Successfully updated high score')
      expect(MachineScoreXref.last.score).to eq(200)
      expect(UserSubmission.last.high_score).to eq(200)
    end

    it 'does not update when you do not own the high score' do
      @evil_user = FactoryBot.create(:user, id: 222, email: 'yeah@ok.com', authentication_token: '123', username: 'sass')
      owned_high_score = FactoryBot.create(:machine_score_xref, user: @user, score: 100)

      put '/api/v1/machine_score_xrefs/' + owned_high_score.id.to_s + '.json', params: { user_email: 'yeah@ok.com', user_token: '123', score: 200 }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('You can only update high scores that you own')
      expect(MachineScoreXref.last.score).to eq(100)
    end
  end
end
