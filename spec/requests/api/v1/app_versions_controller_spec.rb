require 'spec_helper'

describe Api::V1::AppVersionsController, type: :request do
  describe '#index' do
    it 'returns the latest version for each platform' do
      AppVersion.create!(platform: 'ios', latest: '5.5.1')
      AppVersion.create!(platform: 'android', latest: '5.5.0')

      get '/api/v1/app_versions.json'
      expect(response).to be_successful

      expect(JSON.parse(response.body)).to eq('ios' => { 'latest' => '5.5.1' }, 'android' => { 'latest' => '5.5.0' })
    end

    it 'returns null for a platform with no version set' do
      AppVersion.create!(platform: 'ios', latest: '5.5.1')

      get '/api/v1/app_versions.json'

      expect(JSON.parse(response.body)).to eq('ios' => { 'latest' => '5.5.1' }, 'android' => { 'latest' => nil })
    end
  end
end
