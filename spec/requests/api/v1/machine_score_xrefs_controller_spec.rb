require 'spec_helper'

describe Api::V1::MachineScoreXrefsController, type: :request do
  before(:each) do
    @region = FactoryGirl.create(:region, name: 'portland', should_email_machine_removal: 1)
    @location = FactoryGirl.create(:location, name: 'Ground Kontrol', region: @region)
    @machine = FactoryGirl.create(:machine, name: 'Cleo')
    @lmx = FactoryGirl.create(:location_machine_xref, machine_id: @machine.id, location_id: @location.id)

    @score_one = FactoryGirl.create(:machine_score_xref, location_machine_xref: @lmx, score: 123, user_id: FactoryGirl.create(:user, username: 'ssw').id)
    @score_two = FactoryGirl.create(:machine_score_xref, location_machine_xref: @lmx, score: 100, user_id: nil)
  end

  describe '#index' do
    it 'shows all scores for region' do
      chicago = FactoryGirl.create(:region, name: 'Chicago')
      chicago_location = FactoryGirl.create(:location, name: 'Barb', region: chicago)
      chicago_lmx = FactoryGirl.create(:location_machine_xref, location: chicago_location, machine: @machine)
      FactoryGirl.create(:machine_score_xref, location_machine_xref: chicago_lmx, score: 567)

      get '/api/v1/region/portland/machine_score_xrefs.json'
      expect(response).to be_success

      scores = JSON.parse(response.body)['machine_score_xrefs']

      expect(scores.size).to eq(2)
    end

    it 'respects limit scope' do
      get '/api/v1/region/portland/machine_score_xrefs.json', limit: 1
      expect(response).to be_success

      scores = JSON.parse(response.body)['machine_score_xrefs']

      expect(scores.size).to eq(1)
    end

    it 'respects zone_id scope' do
      FactoryGirl.create(:zone, id: 1, region: @region)
      FactoryGirl.create(:zone, id: 2, region: @region)

      3.times do
        FactoryGirl.create(:machine_score_xref, location_machine_xref: FactoryGirl.create(:location_machine_xref, location: FactoryGirl.create(:location, region: @region, zone_id: 1)), score: 100)
      end

      FactoryGirl.create(:machine_score_xref, location_machine_xref: FactoryGirl.create(:location_machine_xref, location: FactoryGirl.create(:location, region: @region, zone_id: 2)), score: 100)

      get '/api/v1/region/portland/machine_score_xrefs.json', zone_id: 1
      expect(response).to be_success

      scores = JSON.parse(response.body)['machine_score_xrefs']

      expect(scores.size).to eq(3)
    end
  end

  describe '#show' do
    it 'shows all scores for lmx' do
      get '/api/v1/machine_score_xrefs/' + @lmx.id.to_s + '.json'
      expect(response).to be_success

      scores = JSON.parse(response.body)['machine_scores']

      expect(scores.size).to eq(2)

      expect(scores[0]['score']).to eq(123)
      expect(scores[0]['username']).to eq('ssw')

      expect(scores[1]['score']).to eq(100)
      expect(scores[1]['username']).to eq('')
    end

    it 'errors for unknown lmx' do
      get '/api/v1/machine_score_xrefs/-1.json'
      expect(response).to be_success

      expect(JSON.parse(response.body)['errors']).to eq('Failed to find machine')
    end
  end

  describe '#create' do
    it 'errors for unknown lmx' do
      post '/api/v1/machine_score_xrefs.json', location_machine_xref_id: -1, score: 1234
      expect(response).to be_success

      expect(JSON.parse(response.body)['errors']).to eq('Failed to find machine')
    end

    it 'errors for blank scores' do
      post '/api/v1/machine_score_xrefs.json', location_machine_xref_id: @lmx.id.to_s
      expect(response).to be_success

      expect(JSON.parse(response.body)['errors']).to eq('Score can not be blank and must be a numeric value')
    end

    it 'errors for failed saves' do
      expect_any_instance_of(MachineScoreXref).to receive(:save).twice.and_return(false)

      post '/api/v1/machine_score_xrefs.json', location_machine_xref_id: @lmx.id.to_s, score: 1234
      expect(response).to be_success

      expect(JSON.parse(response.body)['errors']).to eq([])
    end

    it 'errors when numbers are larger than bigints (>9223372036854775807)' do
      post '/api/v1/machine_score_xrefs.json', location_machine_xref_id: @lmx.id.to_s, score: 9_223_372_036_854_775_808
      expect(response).to be_success

      expect(JSON.parse(response.body)['errors']).to eq('Number is too large. Please enter a valid score.')
    end

    it 'return an error if you enter a non-integer score' do
      post '/api/v1/machine_score_xrefs.json', location_machine_xref_id: @lmx.id.to_s, score: 'fword', user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a'
      expect(response).to be_success

      expect(JSON.parse(response.body)['errors']).to eq('Score can not be blank and must be a numeric value')
    end

    it 'creates a new score -- authed' do
      user = FactoryGirl.create(:user, id: 111, email: 'foo@bar.com', authentication_token: '1G8_s7P-V-4MGojaKD7a')

      post '/api/v1/machine_score_xrefs.json', location_machine_xref_id: @lmx.id.to_s, score: 1234, user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a'
      expect(response).to be_success
      expect(response.status).to eq(201)

      expect(JSON.parse(response.body)['machine_score_xref']['score']).to eq(1234)

      new_score = MachineScoreXref.last

      expect(new_score.score).to eq(1234)
      expect(new_score.location_machine_xref_id).to eq(@lmx.id)
      expect(new_score.user_id).to eq(user.id)

      first_score = MachineScoreXref.first
      expect(first_score.score).to eq(123)
    end
  end
end
