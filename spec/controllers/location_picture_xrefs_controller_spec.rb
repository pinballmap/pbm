require 'spec_helper'

describe LocationPictureXrefsController, type: :controller do
  before(:each) do
    @portland = FactoryBot.create(:region, name: 'portland', full_name: 'Portland')
    @location = FactoryBot.create(:location, name: 'Sassy', region: @portland)
    @user = FactoryBot.create(:user, region: @portland, email: 'foo@bar.com')
    FactoryBot.create(:user, region: FactoryBot.create(:region), email: 'baz@bong.com', is_super_admin: 't')
  end

  describe '#create' do
    it 'creates a user submission' do
      login(@user)

      post 'create', format: :js, params: { location_picture_xref: { location_id: @location.id } }

      user_submission = UserSubmission.last

      expect(user_submission.user_id).to eq(@user.id)
      expect(user_submission.submission_type).to eq(UserSubmission::NEW_PICTURE_TYPE)
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
