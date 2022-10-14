require 'spec_helper'

describe UsersController do
  describe 'Fave Locations', type: :feature, js: true do
    before(:each) do
      @user = FactoryBot.create(:user, username: 'ssw', email: 'ssw@yeah.com', created_at: '02/02/2016')
      page.set_rack_session("warden.user.user.key": User.serialize_into_session(@user))
    end

    it 'lists fave locations for users' do
      FactoryBot.create(:user_fave_location, user: @user, location: FactoryBot.create(:location, name: 'Foo'))
      FactoryBot.create(:user_fave_location, user: @user, location: FactoryBot.create(:location, name: 'Bar'))
      FactoryBot.create(:user_fave_location, location: FactoryBot.create(:location, name: 'Baz'))

      visit "/users/#{@user.id}/fave_locations"

      expect(page).to have_link('Foo')
      expect(page).to have_link('Bar')

      expect(page).to_not have_link('Baz')
    end
  end

  describe 'Profile', type: :feature, js: true do
    before(:each) do
      @user = FactoryBot.create(:user, username: 'ssw', email: 'ssw@yeah.com', created_at: '02/02/2016')
      page.set_rack_session("warden.user.user.key": User.serialize_into_session(@user))
    end

    it 'sets page title appropriately' do
      visit "/users/#{@user.id}/profile"

      title = @user.username + "'s User Profile - Pinball Map"

      desc_tag = "meta[property=\"og:title\"][content=\"#{title}\"]"
      expect(page.body).to have_css(desc_tag, visible: false)
      expect(page.title).to eq(title)
    end

    it 'looks up by user_id or username' do
      title = @user.username + "'s User Profile - Pinball Map"

      visit "/users/#{@user.id}/profile"

      expect(page.title).to eq(title)

      visit "/users/#{@user.username}/profile"

      expect(page.title).to eq(title)
    end

    it 'lists saved locations' do
      FactoryBot.create(:user_fave_location, user: @user, location: FactoryBot.create(:location, name: 'Foo'))
      FactoryBot.create(:user_fave_location, user: @user, location: FactoryBot.create(:location, name: 'Bar'))
      FactoryBot.create(:user_fave_location, location: FactoryBot.create(:location, name: 'Baz'))

      visit "/users/#{@user.id}/profile"

      expect(page).to have_content('Saved Locations:')
      expect(page).to have_link('Foo')
      expect(page).to have_link('Bar')

      expect(page).to_not have_link('Baz')
    end

    it 'display metrics about the users account' do
      FactoryBot.create(:user_submission, user: @user, location: FactoryBot.create(:location, id: 100), submission_type: UserSubmission::NEW_LMX_TYPE)
      FactoryBot.create(:user_submission, user: @user, location: Location.find(100), submission_type: UserSubmission::NEW_CONDITION_TYPE)
      FactoryBot.create(:user_submission, user: @user, location: FactoryBot.create(:location, id: 200), submission_type: UserSubmission::REMOVE_MACHINE_TYPE)
      FactoryBot.create(:user_submission, user: @user, location: FactoryBot.create(:location, id: 300), submission_type: UserSubmission::REMOVE_MACHINE_TYPE)
      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::SUGGEST_LOCATION_TYPE)
      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::SUGGEST_LOCATION_TYPE)
      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::SUGGEST_LOCATION_TYPE)
      FactoryBot.create(:user_submission, user: @user, location: FactoryBot.create(:location, id: 400), submission_type: UserSubmission::LOCATION_METADATA_TYPE)
      FactoryBot.create(:user_submission, user: @user, location: FactoryBot.create(:location, id: 500, name: 'Location One'), machine: FactoryBot.create(:machine, name: 'Machine One'), submission_type: UserSubmission::NEW_SCORE_TYPE, submission: 'ssw added a high score of 1 on Machine One at Location One', created_at: '2016-01-02')

      machine = FactoryBot.create(:machine, name: 'Machine Two')
      FactoryBot.create(:user_submission, user: @user, location: Location.find(400), submission_type: UserSubmission::LOCATION_METADATA_TYPE)

      FactoryBot.create(:user_submission, user: @user, location: Location.find(500), machine: machine, submission_type: UserSubmission::NEW_SCORE_TYPE, submission: 'ssw added a high score of 2 on Machine Two at Location One', created_at: '2016-01-01')
      FactoryBot.create(:user_submission, user: @user, location: Location.find(400), machine: machine, submission_type: UserSubmission::NEW_SCORE_TYPE, submission: 'ssw added a high score of 3 on Machine Two at Location Two', created_at: '2016-01-01')

      login
      visit "/users/#{@user.id}/profile"

      expect(page).to have_link('ssw')
      expect(page).to have_content('Member since: Feb 02, 2016')
      expect(page).to have_content("1\nMachines Added")
      expect(page).to have_content("2\nMachines Removed")
      expect(page).to have_content("1\nMachine Comments")
      expect(page).to have_content("3\nLocations Submitted")
      expect(page).to have_content("5\nLocations Edited")
      expect(page).to have_content("High Scores (Last 50):\nMachine One\n1\nat Location One on Jan 02, 2016\nMachine Two\n3\nat Location Two on Jan 01, 2016")

      expect(page).to_not have_content('Saved Locations:')
    end

    it 'adds commas to high scores' do
      FactoryBot.create(:user_submission, user: @user, location: FactoryBot.create(:location, id: 500, name: 'Location One'), machine: FactoryBot.create(:machine, name: 'Machine One'), submission_type: UserSubmission::NEW_SCORE_TYPE, submission: 'ssw added a high score of 1000000 on Machine One at Location One', created_at: '2016-01-02')

      login
      visit "/users/#{@user.id}/profile"

      expect(page).to have_content("High Scores (Last 50):\nMachine One\n1,000,000\nat Location One on Jan 02, 2016")
    end

    it 'Only lets you edit your own account' do
      not_your_user = FactoryBot.create(:user)

      login(@user)
      visit "/users/#{@user.id}/profile"

      expect(page).to have_content('Update Email / Update Password / Delete Account')

      visit "/users/#{not_your_user.id}/profile"

      expect(page).to have_content('LOGIN to Update Email / Update Password / Delete Account')
    end
  end
end
