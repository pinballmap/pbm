require 'spec_helper'

describe LocationPictureXrefsController, type: :controller do
  before(:each) do
    @portland = FactoryBot.create(:region, name: 'portland', full_name: 'Portland')
    @location = FactoryBot.create(:location, name: 'Sassy', region: @portland)
    @regionless_location = FactoryBot.create(:location, name: 'Bawb', region: nil)
    FactoryBot.create(:user, region: @portland, email: 'foo@bar.com', is_super_admin: 't')
    FactoryBot.create(:user, region: FactoryBot.create(:region), email: 'baz@bong.com', is_super_admin: 't')
  end

  describe '#create' do
    it 'sends an email' do
      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          to: ['foo@bar.com'],
          from: 'admin@pinballmap.com',
          subject: 'PBM - Someone added a picture',
          body: "This is photo ID: 1. It's at location: Sassy. Region: Portland.\n\n\nYou can view the picture here /photos/original/missing.png\n\n\nNo need to approve it, it's already live."
        )
      end

      post 'create', format: :js, params: { location_picture_xref: { location_id: @location.id } }
    end

    it 'sends an email - works for regionless' do
      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          to: ['foo@bar.com', 'baz@bong.com'],
          from: 'admin@pinballmap.com',
          subject: 'PBM - Someone added a picture',
          body: "This is photo ID: 2. It's at location: Bawb. Region: REGIONLESS.\n\n\nYou can view the picture here /photos/original/missing.png\n\n\nNo need to approve it, it's already live."
        )
      end

      post 'create', format: :js, params: { location_picture_xref: { location_id: @regionless_location.id } }
    end
  end
end
