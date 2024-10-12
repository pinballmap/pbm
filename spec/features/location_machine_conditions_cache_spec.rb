require 'spec_helper'

RSpec.feature 'LocationMachineConditionsCaches', type: :feature do
  before(:each) do
    @region = FactoryBot.create(:region, name: 'portland', full_name: 'Portland')
    @location = FactoryBot.create(:location, id: 1, region: @region)
  end

  describe 'machine descriptions cached', type: :feature, js: true do
    before(:each) do
      @lmx = FactoryBot.create(:location_machine_xref, location: @location, machine: FactoryBot.create(:machine))
      @user = FactoryBot.create(:user, id: 11, username: 'ssw', email: 'foo@bar.com')
      @user2 = FactoryBot.create(:user, id: 12, username: 'barnne', email: 'bar@example.com')
    end

    it 'it should show the correctly cached page' do
      # cache the logged out page
      visit "/#{@region.name}/?by_location_id=#{@location.id}"
      sleep 0.5

      Capybara.using_session(:logged_in) do
        # login and add a machine condition and expect the server to save it
        login(@user)

        visit "/#{@region.name}/?by_location_id=#{@location.id}&initials=#{@user.username}"
        sleep 0.5

        # enter a new condition
        page.find("div#machine_tools_lmx_banner_#{@lmx.id}").click
        page.find("div#machine_condition_lmx_#{@lmx.id}.machine_condition_lmx .add_condition").click
        fill_in("new_machine_condition_#{@lmx.id}", with: 'This is a new condition1')
        page.find("input#save_machine_condition_#{@lmx.id}.save_button").click
        page.find("div#show_conditions_lmx_banner_#{@lmx.id}").click

        expect(page).to have_content('This is a new condition1')
      end

      # visit with the logged out session and expect to see the logged in version
      visit "/#{@region.name}/?by_location_id=#{@location.id}"
      sleep 0.5

      page.find("div#machine_tools_lmx_banner_#{@lmx.id}").click
      page.find("#show_conditions_lmx_banner_#{@lmx.id}").click
      expect(page).to have_content('This is a new condition1')
      expect(page).to have_content('Add machine comment')
      expect(page).to have_content('Add high score')

      Capybara.using_session(:logged_in_user2) do
        # login as a second user and add a machine condition and expect the server to save it
        login(@user2)

        visit "/#{@region.name}/?by_location_id=#{@location.id}&initials=#{@user2.username}"
        sleep 0.5

        expect(page).to have_content('Add machine comment')
        expect(page).to have_content('Add high score')

        # enter a new condition
        page.find("div#machine_tools_lmx_banner_#{@lmx.id}").click
        page.find("div#machine_condition_lmx_#{@lmx.id}.machine_condition_lmx .add_condition").click
        fill_in("new_machine_condition_#{@lmx.id}", with: 'This is a new condition2')
        page.find("input#save_machine_condition_#{@lmx.id}.save_button").click
        page.find("div#show_conditions_lmx_banner_#{@lmx.id}").click
        expect(page).to have_content('This is a new condition2')
      end

      # visit with the logged out session and expect to see the logged new content
      visit "/#{@region.name}/?by_location_id=#{@location.id}"
      sleep 0.5

      page.find("div#machine_tools_lmx_banner_#{@lmx.id}").click
      page.find("#show_conditions_lmx_banner_#{@lmx.id}").click
      expect(page).to have_content('This is a new condition1')
      expect(page).to have_content('This is a new condition2')
      expect(page).to have_content('Add machine comment')
      expect(page).to have_content('Add high score')

      Capybara.using_session(:logged_in) do
        # Visit the page again as the first logged in user and expect the new content
        expect(page).not_to have_content('This is a new condition2')
        visit "/#{@region.name}/?by_location_id=#{@location.id}&initials=#{@user.username}"
        sleep 0.5

        page.find("#show_conditions_lmx_banner_#{@lmx.id}").click
        expect(page).to have_content('This is a new condition1')
        expect(page).to have_content('This is a new condition2')
        expect(page).to have_content('Add machine comment')
        expect(page).to have_content('Add high score')
      end
    end

    xit 'it should update the cache when adding a new machine'
    xit 'it should update the cache when adding a new score'
  end
end
