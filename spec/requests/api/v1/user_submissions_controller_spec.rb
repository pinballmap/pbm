require 'spec_helper'

describe Api::V1::UserSubmissionsController, type: :request do
  before(:each) do
    @region = FactoryBot.create(:region, name: 'portland')
  end

  describe '#list_within_range' do
    it 'returns all submissions within range' do
      location = FactoryBot.create(:location, lat: '45.6008356', lon: '-122.760606')
      another_location = FactoryBot.create(:location, lat: '45.6008355', lon: '-122.760606')
      distant_location = FactoryBot.create(:location, lat: '12.6008356', lon: '-12.760606')

      FactoryBot.create(:user_submission, created_at: Time.now.strftime('%Y-%m-%d'), location: location, submission_type: UserSubmission::NEW_LMX_TYPE)
      FactoryBot.create(:user_submission, created_at: Time.now.strftime('%Y-%m-%d'), location: location, submission_type: UserSubmission::REMOVE_MACHINE_TYPE)
      FactoryBot.create(:user_submission, created_at: Time.now.strftime('%Y-%m-%d'), location: another_location, submission_type: UserSubmission::REMOVE_MACHINE_TYPE)
      FactoryBot.create(:user_submission, created_at: Time.now.strftime('%Y-%m-%d'), location: another_location, submission_type: UserSubmission::NEW_CONDITION_TYPE)
      FactoryBot.create(:user_submission, created_at: Time.now.strftime('%Y-%m-%d'), location: another_location, submission_type: UserSubmission::CONFIRM_LOCATION_TYPE)
      FactoryBot.create(:user_submission, created_at: Time.now.strftime('%Y-%m-%d'), location: another_location, submission_type: UserSubmission::NEW_SCORE_TYPE)
      FactoryBot.create(:user_submission, created_at: Time.now.strftime('%Y-%m-%d'), location: another_location, submission_type: UserSubmission::LOCATION_METADATA_TYPE)

      FactoryBot.create(:user_submission, created_at: Time.now.strftime('%Y-%m-%d'), user: @user, submission_type: UserSubmission::NEW_SCORE_TYPE, submission: 'User ssw (scott.wainstock@gmail.com) added a score of 1234 for Cheetah to Bottles')
      FactoryBot.create(:user_submission, created_at: Time.now.strftime('%Y-%m-%d'), user: @user, submission_type: UserSubmission::NEW_SCORE_TYPE, submission: 'User ssw (scott.wainstock@gmail.com) added a score of 12 for Machine to Location')

      FactoryBot.create(:user_submission, location: distant_location, submission_type: 'remove_machine', submission: 'foo')

      get '/api/v1/user_submissions/list_within_range.json', params: { lat: '45.6008356', lon: '-122.760606' }

      expect(response).to be_successful
      json = JSON.parse(response.body)['user_submissions']

      expect(json.count).to eq(7)
    end

    it 'respects date range filtering' do
      location = FactoryBot.create(:location, lat: '45.6008356', lon: '-122.760606')
      another_location = FactoryBot.create(:location, lat: '45.6008355', lon: '-122.760606')

      FactoryBot.create(:user_submission, user: @user, location: location, submission_type: UserSubmission::NEW_SCORE_TYPE, created_at: Time.now.strftime('%Y-%m-%d'), submission: 'User ssw (scott.wainstock@gmail.com) added a score of 12 for Machine to Location')
      FactoryBot.create(:user_submission, created_at: Time.now.strftime('%Y-%m-%d'), location: location, submission_type: UserSubmission::NEW_LMX_TYPE)
      FactoryBot.create(:user_submission, created_at: Time.now.strftime('%Y-%m-%d'), location: another_location, submission_type: UserSubmission::NEW_LMX_TYPE)
      FactoryBot.create(:user_submission, created_at: (Date.today - 30).strftime('%Y-%m-%d'), location: location, submission_type: UserSubmission::NEW_LMX_TYPE)

      get '/api/v1/user_submissions/list_within_range.json', params: { lat: '45.6008356', lon: '-122.760606', submission_type: UserSubmission::NEW_LMX_TYPE }

      expect(response).to be_successful
      json = JSON.parse(response.body)['user_submissions']

      expect(json.count).to eq(2)
    end

    it 'respects type filter' do
      location = FactoryBot.create(:location, lat: '45.6008356', lon: '-122.760606')

      FactoryBot.create(:user_submission, user: @user, location: location, submission_type: UserSubmission::NEW_SCORE_TYPE, created_at: '2016-01-01', submission: 'User ssw (scott.wainstock@gmail.com) added a score of 1234 for Cheetah to Bottles')
      FactoryBot.create(:user_submission, user: @user, location: location, submission_type: UserSubmission::NEW_SCORE_TYPE, created_at: Time.now.strftime('%Y-%m-%d'), submission: 'User ssw (scott.wainstock@gmail.com) added a score of 12 for Machine to Location')

      get '/api/v1/user_submissions/list_within_range.json', params: { lat: '45.6008356', lon: '-122.760606' }

      expect(response).to be_successful
      json = JSON.parse(response.body)['user_submissions']

      expect(json.count).to eq(1)
    end
  end

  describe '#index' do
    it 'returns all submissions within scope' do
      FactoryBot.create(:user_submission, region: @region, submission_type: 'remove_machine', submission: 'foo')
      FactoryBot.create(:user_submission, region: FactoryBot.create(:region, name: 'chicago'), submission_type: 'remove_machine', submission: 'foo')
      get "/api/v1/region/#{@region.name}/user_submissions.json"

      expect(response.body).to include('remove_machine')
      expect(response.body).to include('foo')

      expect(response.body).to_not include('bar')
    end

    it 'only shows remove_machine submissions' do
      FactoryBot.create(:user_submission, region: @region, submission_type: 'remove_machine', submission: 'removed foo from bar')
      FactoryBot.create(:user_submission, region: @region, submission_type: 'DO_NOT_SHOW', submission: 'hope this does not show')
      get "/api/v1/region/#{@region.name}/user_submissions.json"

      expect(response.body).to include('remove_machine')
      expect(response.body).to include('removed foo from bar')

      expect(response.body).to_not include('DO_NOT_SHOW')
      expect(response.body).to_not include('hope this does not show')
    end
  end
end
