require 'spec_helper'

describe Api::V1::LocationPictureXrefsController, type: :request do
  before(:each) do
    @location = FactoryBot.create(:location, id: 1, name: 'Ground Kontrol')
    FactoryBot.create(:user, email: 'foo@bar.com', authentication_token: '1G8_s7P-V-4MGojaKD7a', username: 'ssw')
    Aws.config[:s3] = { stub_responses: true }
  end
  describe '#create' do
    it 'creates a user submission for the new picture' do
      post '/api/v1/location_picture_xrefs.json', params: { location_id: @location.id.to_s, photo: fixture_file_upload('PPM-Splash-200.png', 'image/png'), user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', format: :js }

      expect(response).to be_successful
      expect(response.body).to include('location_picture')
      expect(UserSubmission.count).to eq(1)
      submission = UserSubmission.last
      expect(submission.submission_type).to eq(UserSubmission::NEW_PICTURE_TYPE)
    end
  end
end
