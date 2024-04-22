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

    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
  end

  after(:each) do
    ActionMailer::Base.deliveries.clear
  end

  describe '#create' do
    it 'sends an email' do
      login(@user)

      expect do
        post 'create', format: :js, params: { location_picture_xref: { location_id: @location.id } }
        email = ActionMailer::Base.deliveries.last
        expect(email.subject).to eq('Pinball Map - Picture added')
        expect(email.from).to eq(['admin@pinballmap.com'])
        expect(email.to).to eq(['foo@bar.com'])
        expect(email.body).to have_content('Photo ID: 1')
        expect(email.body).to have_content('Location: Sassy')
        expect(email.body).to have_content('Photo: /photos/large/missing.png')
        expect(email.body).to have_content('Region: Portland')
        expect(email.body).to have_content("No need to approve it, it's already live.")
      end.to change { ActionMailer::Base.deliveries.size }.by(1)
    end

    it 'sends an email - works for regionless' do
      login(@user)

      expect do
        post 'create', format: :js, params: { location_picture_xref: { location_id: @regionless_location.id } }
        email = ActionMailer::Base.deliveries.last
        expect(email.subject).to eq('Pinball Map - Picture added')
        expect(email.from).to eq(['admin@pinballmap.com'])
        expect(email.to).to eq(['baz@bong.com'])
        expect(email.body).to have_content('Photo ID: 2')
        expect(email.body).to have_content('Location: Bawb')
        expect(email.body).to have_content('Photo: /photos/large/missing.png')
        expect(email.body).to have_content('Region: REGIONLESS')
        expect(email.body).to have_content("No need to approve it, it's already live.")
      end.to change { ActionMailer::Base.deliveries.size }.by(1)
    end

    it 'sends an email - works for regions that do not have an admin' do
      login(@user)

      expect do
        post 'create', format: :js, params: { location_picture_xref: { location_id: @no_admin_location.id } }
        email = ActionMailer::Base.deliveries.last
        expect(email.subject).to eq('Pinball Map - Picture added')
        expect(email.from).to eq(['admin@pinballmap.com'])
        expect(email.to).to eq(['baz@bong.com'])
        expect(email.body).to have_content('Photo ID: 3')
        expect(email.body).to have_content('Location: Cleo')
        expect(email.body).to have_content('Photo: /photos/large/missing.png')
        expect(email.body).to have_content('Region: Seattle')
        expect(email.body).to have_content("No need to approve it, it's already live.")
      end.to change { ActionMailer::Base.deliveries.size }.by(1)
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
