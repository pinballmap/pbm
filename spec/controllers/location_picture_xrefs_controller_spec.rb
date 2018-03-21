require 'spec_helper'

describe LocationPictureXrefsController, type: :controller do
  before(:each) do
    @portland = FactoryBot.create(:region, name: 'portland', full_name: 'Portland')
    @location = FactoryBot.create(:location, name: 'Sassy', region: @portland)
    FactoryBot.create(:user, region: @portland, email: 'foo@bar.com')
  end

  describe '#create' do
    it 'sends an email' do
      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          to: ['foo@bar.com'],
          from: 'admin@pinballmap.com',
          subject: 'PBM - Someone wants you to approve a picture',
          body: "This is photo ID: 1. It's at location: Sassy. Region: Portland.\n\n\nYou can view the picture here /photos/original/missing.png\n\n\nTo approve it, please visit here http://test.host/admin/location_picture_xref\n\n\nOnce there, click 'edit' and then tick the 'approve' button."
        )
      end

      post 'create', format: :js, params: { location_picture_xref: { location_id: @location.id } }
    end
  end
end
