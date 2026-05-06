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
