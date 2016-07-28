require 'spec_helper'

describe Api::V1::MachineScoreXrefsController, type: :request do
  before(:each) do
    @region = FactoryGirl.create(:region, name: 'portland', should_email_machine_removal: 1)
    @location = FactoryGirl.create(:location, name: 'Ground Kontrol', region: @region)
    @machine = FactoryGirl.create(:machine, name: 'Cleo')
    @lmx = FactoryGirl.create(:location_machine_xref, machine_id: @machine.id, location_id: @location.id)

    @score_rank_1 = FactoryGirl.create(:machine_score_xref, location_machine_xref: @lmx, rank: 1, score: 123, initials: 'abc', user_id: FactoryGirl.create(:user, :username => 'ssw').id)
    @score_rank_2 = FactoryGirl.create(:machine_score_xref, location_machine_xref: @lmx, rank: 2, score: 100, initials: 'def', user_id: nil)
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
      get '/api/v1/region/portland/machine_score_xrefs.json?limit=1'
      expect(response).to be_success

      scores = JSON.parse(response.body)['machine_score_xrefs']

      expect(scores.size).to eq(1)
    end
  end

  describe '#show' do
    it 'shows all scores for lmx' do
      get '/api/v1/machine_score_xrefs/' + @lmx.id.to_s + '.json'
      expect(response).to be_success

      scores = JSON.parse(response.body)['machine_scores']

      expect(scores.size).to eq(2)

      expect(scores[0]['rank']).to eq(1)
      expect(scores[0]['initials']).to eq('abc')
      expect(scores[0]['score']).to eq(123)
      expect(scores[0]['username']).to eq('ssw')

      expect(scores[1]['rank']).to eq(2)
      expect(scores[1]['initials']).to eq('def')
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
      post '/api/v1/machine_score_xrefs.json?location_machine_xref_id=-1'
      expect(response).to be_success

      expect(JSON.parse(response.body)['errors']).to eq('Failed to find machine')
    end

    it 'errors for failed saves' do
      expect_any_instance_of(MachineScoreXref).to receive(:save).twice.and_return(false)

      post '/api/v1/machine_score_xrefs.json?location_machine_xref_id=' + @lmx.id.to_s + ';score=1234'
      expect(response).to be_success

      expect(JSON.parse(response.body)['errors']).to eq([])
    end

    it 'creates a new score' do
      post '/api/v1/machine_score_xrefs.json?location_machine_xref_id=' + @lmx.id.to_s + ';score=1,234;initials=abc;rank=1'
      expect(response).to be_success
      expect(response.status).to eq(201)

      expect(JSON.parse(response.body)['msg']).to eq('Added your score!')

      new_score = MachineScoreXref.last

      expect(new_score.initials).to eq('abc')
      expect(new_score.rank).to eq(1)
      expect(new_score.score).to eq(1234)
      expect(new_score.location_machine_xref_id).to eq(@lmx.id)

      first_score = MachineScoreXref.first
      expect(first_score.rank).to eq(2)
    end
  end
end
