require 'spec_helper'

describe LocationPictureXrefsController, type: :controller do
  before(:each) do
    @portland = FactoryBot.create(:region, name: 'portland', full_name: 'Portland')
    @location = FactoryBot.create(:location, name: 'Sassy', region: @portland)
    @seattle = FactoryBot.create(:region, name: 'seattle', full_name: 'Seattle')
    @regionless_location = FactoryBot.create(:location, name: 'Bawb', region: nil)
    @no_admin_location = FactoryBot.create(:location, name: 'Cleo', region: @seattle)
    FactoryBot.create(:user, region: @portland, email: 'foo@bar.com')
    FactoryBot.create(:user, region: FactoryBot.create(:region), email: 'baz@bong.com', is_super_admin: 't')
  end

  describe '#create' do
    it 'sends an email' do
      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          to: ['foo@bar.com'],
          from: 'admin@pinballmap.com',
          subject: 'PBM - Someone added a picture',
          body: "This is photo ID: 1. It's at location: Sassy. Region: Portland.\n\n\nYou can view the picture here /photos/large/missing.png\n\n\nNo need to approve it, it's already live."
        )
      end

      post 'create', format: :js, params: { location_picture_xref: { location_id: @location.id } }
    end

    it 'sends an email - works for regionless' do
      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          to: ['baz@bong.com'],
          from: 'admin@pinballmap.com',
          subject: 'PBM - Someone added a picture',
          body: "This is photo ID: 2. It's at location: Bawb. Region: REGIONLESS.\n\n\nYou can view the picture here /photos/large/missing.png\n\n\nNo need to approve it, it's already live."
        )
      end

      post 'create', format: :js, params: { location_picture_xref: { location_id: @regionless_location.id } }
    end

    it 'sends an email - works for regions that do not have an admin' do
      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          to: ['baz@bong.com'],
          from: 'admin@pinballmap.com',
          subject: 'PBM - Someone added a picture',
          body: "This is photo ID: 3. It's at location: Cleo. Region: Seattle.\n\n\nYou can view the picture here /photos/large/missing.png\n\n\nNo need to approve it, it's already live."
        )
      end

      post 'create', format: :js, params: { location_picture_xref: { location_id: @no_admin_location.id } }
    end
  end
end
