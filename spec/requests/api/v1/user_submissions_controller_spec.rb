require 'spec_helper'

describe Api::V1::UserSubmissionsController, type: :request do
  before(:each) do
    @region = FactoryGirl.create(:region, name: 'portland')
  end

  describe '#index' do
    it 'returns all submissions within scope' do
      FactoryGirl.create(:user_submission, region: @region, submission_type: 'remove_machine', submission: 'foo')
      FactoryGirl.create(:user_submission, region: FactoryGirl.create(:region, name: 'chicago'), submission_type: 'remove_machine', submission: 'foo')
      get "/api/v1/region/#{@region.name}/user_submissions.json"

      expect(response.body).to include('remove_machine')
      expect(response.body).to include('foo')

      expect(response.body).to_not include('bar')
    end

    it 'only shows remove_machine submissions' do
      FactoryGirl.create(:user_submission, region: @region, submission_type: 'remove_machine', submission: 'removed foo from bar')
      FactoryGirl.create(:user_submission, region: @region, submission_type: 'DO_NOT_SHOW', submission: 'hope this does not show')
      get "/api/v1/region/#{@region.name}/user_submissions.json"

      expect(response.body).to include('remove_machine')
      expect(response.body).to include('removed foo from bar')

      expect(response.body).to_not include('DO_NOT_SHOW')
      expect(response.body).to_not include('hope this does not show')
    end
  end
end
