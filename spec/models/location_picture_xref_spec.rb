require 'spec_helper'

describe LocationPictureXref, type: :model do
  let(:location) { FactoryBot.create(:location) }
  let(:user) { FactoryBot.create(:user) }
  let(:lpx) { LocationPictureXref.new(location: location, user: user) }

  def attach_png(record)
    record.photo.attach(
      io: File.open(Rails.root.join('spec/fixtures/files/PPM-Splash-200.png')),
      filename: 'PPM-Splash-200.png',
      content_type: 'image/png'
    )
  end

  describe 'photo content type validation' do
    it 'accepts a PNG' do
      attach_png(lpx)
      expect(lpx).to be_valid
    end

    it 'rejects a disallowed content type' do
      lpx.photo.attach(io: StringIO.new('not an image'), filename: 'file.pdf', content_type: 'application/pdf')
      expect(lpx).not_to be_valid
      expect(lpx.errors[:photo]).to be_present
    end
  end

  describe 'photo size validation' do
    it 'rejects files over 30MB' do
      attach_png(lpx)
      allow(lpx.photo.blob).to receive(:byte_size).and_return(31.megabytes)
      expect(lpx).not_to be_valid
      expect(lpx.errors[:photo]).to be_present
    end
  end

  describe '#create_remove_user_submission' do
    it 'creates a remove_picture user submission with correct attributes' do
      lpx = LocationPictureXref.new(location: location, user: user)
      lpx.save!(validate: false)

      lpx.create_remove_user_submission(user)

      submission = UserSubmission.last
      expect(submission.submission_type).to eq(UserSubmission::REMOVE_PICTURE_TYPE)
      expect(submission.user_id).to eq(user.id)
      expect(submission.location_id).to eq(location.id)
      expect(submission.user_name).to eq(user.username)
      expect(submission.location_name).to eq(location.name)
      expect(submission.city_name).to eq(location.city)
      expect(submission.lat).to eq(location.lat)
      expect(submission.lon).to eq(location.lon)
      expect(submission.region_id).to eq(location.region_id)
      expect(submission.submission).to include("removed a picture of #{location.name}")
    end

    it 'uses UNKNOWN USER when removing_user is nil' do
      lpx = LocationPictureXref.new(location: location, user: user)
      lpx.save!(validate: false)

      lpx.create_remove_user_submission(nil)

      expect(UserSubmission.last.submission).to include("UNKNOWN USER removed a picture")
    end

    it 'does not appear in the activity feed' do
      lpx = LocationPictureXref.new(location: location, user: user)
      lpx.save!(validate: false)
      lpx.create_remove_user_submission(user)

      expect(UserSubmission::ACTIVITY_SUBMISSION_TYPES).not_to include(UserSubmission::REMOVE_PICTURE_TYPE)
    end
  end

  describe 'variant generation' do
    it 'enqueues GeneratePhotoVariantsJob after create' do
      attach_png(lpx)
      expect(GeneratePhotoVariantsJob).to receive(:perform_later).with(kind_of(Integer))
      lpx.save!
    end

    it 'does not enqueue GeneratePhotoVariantsJob when no photo is attached' do
      expect(GeneratePhotoVariantsJob).not_to receive(:perform_later)
      lpx.save!(validate: false)
    end
  end
end
