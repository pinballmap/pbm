require 'spec_helper'

describe Api::V1::MachineScoreXrefsController do
  before(:each) do
    @region = FactoryGirl.create(:region, :name => 'portland', :should_email_machine_removal => 1)
    @location = FactoryGirl.create(:location, :name => 'Ground Kontrol', :region => @region)
    @machine = FactoryGirl.create(:machine, :name => 'Cleo')
    @lmx = FactoryGirl.create(:location_machine_xref, :machine_id => @machine.id, :location_id => @location.id)

    @score_rank_1 = FactoryGirl.create(:machine_score_xref, :location_machine_xref => @lmx, :rank => 1, :score => 123, :initials => 'abc')
    @score_rank_2 = FactoryGirl.create(:machine_score_xref, :location_machine_xref => @lmx, :rank => 2, :score => 100, :initials => 'def')
  end

  describe '#index' do
    it 'shows all scores for region' do
      chicago = FactoryGirl.create(:region, :name => 'Chicago')
      chicago_location = FactoryGirl.create(:location, :name => 'Barb', :region => chicago)
      chicago_lmx = FactoryGirl.create(:location_machine_xref, :location => chicago_location, :machine => @machine)
      chicago_msx = FactoryGirl.create(:machine_score_xref, :location_machine_xref => chicago_lmx, :score => 567)

      get '/api/v1/region/portland/machine_score_xrefs.json'
      expect(response).to be_success

      scores = JSON.parse(response.body)['machine_score_xrefs']

      scores.size.should == 2
    end

    it 'respects limit scope' do
      get '/api/v1/region/portland/machine_score_xrefs.json?limit=1'
      expect(response).to be_success

      scores = JSON.parse(response.body)['machine_score_xrefs']

      scores.size.should == 1
    end
  end

  describe '#show' do
    it 'shows all scores for lmx' do
      get '/api/v1/machine_score_xrefs/' + @lmx.id.to_s + '.json'
      expect(response).to be_success

      scores = JSON.parse(response.body)['machine_scores']

      scores.size.should == 2

      scores[0]['rank'].should == 2
      scores[0]['initials'].should == 'def'
      scores[0]['score'].should == 100

      scores[1]['rank'].should == 1
      scores[1]['initials'].should == 'abc'
      scores[1]['score'].should == 123
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

      JSON.parse(response.body)['errors'].should == 'Failed to find machine'
    end

    it 'creates a new score' do
      post '/api/v1/machine_score_xrefs.json?location_machine_xref_id=' + @lmx.id.to_s + ';score=1,234;initials=abc;rank=1'
      expect(response).to be_success

      expect(JSON.parse(response.body)['msg']).to eq('Added your score!')

      new_score = MachineScoreXref.last

      new_score.initials.should == 'abc'
      new_score.rank.should == 1
      new_score.score.should == 1234
      new_score.location_machine_xref_id.should == @lmx.id

      first_score = MachineScoreXref.first
      first_score.rank.should == 2
    end
  end
end
