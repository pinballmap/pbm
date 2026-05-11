require 'spec_helper'

describe UserSubmissionsController, type: :controller do
  before(:each) do
    @user = FactoryBot.create(:user, username: 'ssw', email: 'ssw@yeah.com')
    login(@user)

    @location = FactoryBot.create(:location, lat: '45.6008356', lon: '-122.760606')
  end

  let(:bounds_params) do
    {
      boundsData: {
        sw: { lat: '45.0', lng: '-123.5' },
        ne: { lat: '46.0', lng: '-122.0' }
      }
    }
  end

  describe '#list_within_range' do
    before(:each) do
      @lmx_submission = FactoryBot.create(:user_submission, location: @location, lat: @location.lat, lon: @location.lon, submission_type: 'new_lmx', submission: 'Machine added', location_name: @location.name)
      @remove_submission = FactoryBot.create(:user_submission, location: @location, lat: @location.lat, lon: @location.lon, submission_type: 'remove_machine', submission: 'Machine removed', location_name: @location.name)
      @score_submission = FactoryBot.create(:user_submission, location: @location, lat: @location.lat, lon: @location.lon, submission_type: 'new_msx', user: @user, submission: 'Score added', location_name: @location.name)
    end

    it 'returns all activity types when no filter is specified' do
      get 'list_within_range', params: bounds_params

      expect(response).to be_successful
      submissions = assigns(:recent_activity)
      expect(submissions).to include(@lmx_submission)
      expect(submissions).to include(@remove_submission)
      expect(submissions).to include(@score_submission)
    end

    it 'filters to a single specified submission type' do
      get 'list_within_range', params: bounds_params.merge(submission_type: ['new_lmx'])

      expect(response).to be_successful
      submissions = assigns(:recent_activity)
      expect(submissions).to include(@lmx_submission)
      expect(submissions).to_not include(@remove_submission)
      expect(submissions).to_not include(@score_submission)
    end

    it 'filters to multiple specified submission types' do
      get 'list_within_range', params: bounds_params.merge(submission_type: ['new_lmx', 'remove_machine'])

      expect(response).to be_successful
      submissions = assigns(:recent_activity)
      expect(submissions).to include(@lmx_submission)
      expect(submissions).to include(@remove_submission)
      expect(submissions).to_not include(@score_submission)
    end

    it 'returns only the current user\'s scores when new_msx is the only filter' do
      other_user = FactoryBot.create(:user, username: 'other', email: 'other@example.com')
      other_score = FactoryBot.create(:user_submission, location: @location, lat: @location.lat, lon: @location.lon, submission_type: 'new_msx', user: other_user, submission: 'Other user score', location_name: @location.name)

      get 'list_within_range', params: bounds_params.merge(submission_type: ['new_msx'])

      expect(response).to be_successful
      submissions = assigns(:recent_activity)
      expect(submissions).to include(@score_submission)
      expect(submissions).to_not include(other_score)
    end

    it 'does not return new_msx submissions when logged out and new_msx is the only filter' do
      login(nil)

      get 'list_within_range', params: bounds_params.merge(submission_type: ['new_msx'])

      expect(response).to be_successful
      expect(assigns(:recent_activity)).to be_empty
    end

    it 'does not return new_msx submissions when logged out and no filter is specified' do
      login(nil)

      get 'list_within_range', params: bounds_params

      expect(response).to be_successful
      submissions = assigns(:recent_activity)
      expect(submissions).to include(@lmx_submission)
      expect(submissions).to_not include(@score_submission)
    end

    it 'returns all activity types when an empty filter array is given' do
      get 'list_within_range', params: bounds_params.merge(submission_type: [])

      expect(response).to be_successful
      submissions = assigns(:recent_activity)
      expect(submissions).to include(@lmx_submission)
      expect(submissions).to include(@remove_submission)
      expect(submissions).to include(@score_submission)
    end

    it 'excludes submissions outside the bounding box' do
      distant_location = FactoryBot.create(:location, lat: '12.0', lon: '-12.0')
      distant_submission = FactoryBot.create(:user_submission, location: distant_location, lat: distant_location.lat, lon: distant_location.lon, submission_type: 'new_lmx', submission: 'Distant submission', location_name: distant_location.name)

      get 'list_within_range', params: bounds_params

      expect(response).to be_successful
      expect(assigns(:recent_activity)).to_not include(distant_submission)
    end
  end
end
