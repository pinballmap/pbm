require 'spec_helper'

describe LocationPictureXrefsController, type: :controller do
  before(:each) do
    @portland = FactoryBot.create(:region, name: 'portland', full_name: 'Portland')
    @location = FactoryBot.create(:location, name: 'Sassy', region: @portland)
    @seattle = FactoryBot.create(:region, name: 'seattle', full_name: 'Seattle')
    @regionless_location = FactoryBot.create(:location, name: 'Bawb', region: nil)
    @no_admin_location = FactoryBot.create(:location, name: 'Cleo', region: @seattle)
    @user = FactoryBot.create(:user, region: @portland, email: 'foo@bar.com')
    FactoryBot.create(:user, region: FactoryBot.create(:region), email: 'baz@bong.com', is_super_admin: 't')
  end

  describe '#create' do
    it 'sends an email' do
      login(@user)

      expect { post 'create', format: :js, params: { location_picture_xref: { location_id: @location.id } } }.to have_enqueued_job(ActionMailer::MailDeliveryJob).with('AdminMailer', 'picture_added', 'deliver_now', { params: { to_users: ['foo@bar.com'], subject: 'Pinball Map - Picture added', photo_id: 1, location_name: 'Sassy', region_name: 'Portland', photo_url: '/photos/large/missing.png' }, args: [] })
    end

    it 'sends an email - works for regionless' do
      login(@user)

      expect { post 'create', format: :js, params: { location_picture_xref: { location_id: @regionless_location.id } } }.to have_enqueued_job(ActionMailer::MailDeliveryJob).with('AdminMailer', 'picture_added', 'deliver_now', { params: { to_users: ['baz@bong.com'], subject: 'Pinball Map - Picture added', photo_id: 2, location_name: 'Bawb', region_name: 'REGIONLESS', photo_url: '/photos/large/missing.png' }, args: [] })
    end

    it 'sends an email - works for regions that do not have an admin' do
      login(@user)

      expect { post 'create', format: :js, params: { location_picture_xref: { location_id: @no_admin_location.id } } }.to have_enqueued_job(ActionMailer::MailDeliveryJob).with('AdminMailer', 'picture_added', 'deliver_now', { params: { to_users: ['baz@bong.com'], subject: 'Pinball Map - Picture added', photo_id: 3, location_name: 'Cleo', region_name: 'Seattle', photo_url: '/photos/large/missing.png' }, args: [] })
    end
  end

  describe 'add picture - not authed', type: :feature, js: true do
    it 'Should not allow you to add pictures if you are not logged in' do
      @location.reload

      sleep 0.5

      visit '/portland/?by_location_id=' + @location.id.to_s

      sleep 0.5

      expect(page).to_not have_selector("#add_picture_location_banner_#{@location.reload.id}")
    end
  end
end
