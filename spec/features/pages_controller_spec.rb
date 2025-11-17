require 'spec_helper'

describe PagesController do
  before(:each) do
    @region = FactoryBot.create(:region, name: 'portland', full_name: 'Portland')
    @location = FactoryBot.create(:location, id: 41, region: @region, state: 'OR', name: "Clark's Depot")
  end

  describe 'High roller list', type: :feature, js: true do
    it 'should have intro text that displays correct number of locations and machines for a region' do
      chicago_region = FactoryBot.create(:region, name: 'chicago')
      portland_location = FactoryBot.create(:location, region: @region)
      chicago_location = FactoryBot.create(:location, region: chicago_region)

      machine = FactoryBot.create(:machine)

      portland_lmx = FactoryBot.create(:location_machine_xref, location: @location, machine: machine)
      another_portland_lmx = FactoryBot.create(:location_machine_xref, location: portland_location, machine: machine)
      FactoryBot.create(:location_machine_xref, location: chicago_location, machine: machine)

      ssw_user = FactoryBot.create(:user, username: 'ssw')
      rtgt_user = FactoryBot.create(:user, username: 'rtgt')
      FactoryBot.create(:machine_score_xref, location_machine_xref: portland_lmx, score: 100, user: ssw_user)
      FactoryBot.create(:machine_score_xref, location_machine_xref: portland_lmx, score: 90, user: rtgt_user)
      FactoryBot.create(:machine_score_xref, location_machine_xref: another_portland_lmx, score: 200, user: ssw_user)

      visit '/portland/high_rollers'

      expect(page).to have_content('ssw: with 2 scores')
      expect(page).to have_content('rtgt: with 1 scores')
    end
  end

  describe 'Top 10 Machine Counts', type: :feature, js: true do
    it 'shows the top 10 machine counts on the about page' do
      11.times do |machine_name_counter|
        machine_name_counter.times do
          FactoryBot.create(:location_machine_xref, location: @location, machine: Machine.where(name: "Machine#{machine_name_counter}").first_or_create)
        end
      end

      visit '/portland/about'

      expect(page).to have_content("Machine10: with 10 machines\nMachine9: with 9 machines\nMachine8: with 8 machines\nMachine7: with 7 machines\nMachine6: with 6 machines\nMachine5: with 5 machines\nMachine4: with 4 machines\nMachine3: with 3 machines\nMachine2: with 2 machines\nMachine1: with 1 machines")
    end
  end

  describe 'Links', type: :feature, js: true do
    it 'shows links in a region' do
      chicago = FactoryBot.create(:region, name: 'chicago', full_name: 'Chicago')

      FactoryBot.create(:region_link_xref, region: @region, description: 'foo')
      FactoryBot.create(:region_link_xref, region: chicago, name: 'chicago link 1', category: 'main links', sort_order: 2, description: 'desc1')
      FactoryBot.create(:region_link_xref, region: chicago, name: 'cool link 1', category: 'cool links', sort_order: 1, description: 'desc2')

      visit '/chicago/about'

      expect(page).to have_content("cool links\ncool link 1\ndesc2\nmain links\nchicago link 1\ndesc1")
    end

    it 'sort order does not cause headers to display twice' do
      FactoryBot.create(:region_link_xref, region: @region, description: 'desc', name: 'link 1', category: 'main links', sort_order: 2)
      FactoryBot.create(:region_link_xref, region: @region, description: 'desc', name: 'link 2', category: 'main links', sort_order: 1)
      FactoryBot.create(:region_link_xref, region: @region, description: 'desc', name: 'link 3', category: 'other category')

      visit "/#{@region.name}/about"

      expect(page).to have_content("main links\nlink 2\ndesc\nlink 1\ndesc\nother category\nlink 3\ndesc")
    end

    it 'makes a default link category called "Links"' do
      FactoryBot.create(:region_link_xref, region: @region, name: 'link 1', description: nil, category: nil)
      FactoryBot.create(:region_link_xref, region: @region, name: 'link 2', description: nil, category: '')
      FactoryBot.create(:region_link_xref, region: @region, name: 'link 3', description: nil, category: ' ')
      FactoryBot.create(:region_link_xref, region: @region, name: 'link 4', description: nil, category: 'other category')

      visit "/#{@region.name}/about"

      expect(page).to have_content("Links\nlink 1\nlink 2\nlink 3\nother category\nlink 4")
    end

    it 'Mixing sort_order and nil sort_order links does not error' do
      FactoryBot.create(:region_link_xref, region: @region, name: 'Minnesota Pinball - The "Pin Cities"', url: 'https://somesite.site', description: 'Your best source for everything pinball in Minnesota!  Events, leagues, locations, games and more!', category: 'Pinball Map Links', sort_order: 1)
      FactoryBot.create(:region_link_xref, region: @region, name: 'Pinball Map Store', url: 'http://blog.pinballmap.com', description: 'News, questions, feelings.', category: 'Pinball Map Links', sort_order: nil)

      visit "/#{@region.name}/about"

      expect(page).to have_content("Links\nPinball Map Store\nNews, questions, feelings.\nMinnesota Pinball - The \"Pin Cities\"\nYour best source for everything pinball in Minnesota! Events, leagues, locations, games and more!")
    end
  end

  describe 'Location suggestions', type: :feature, js: true do
    it 'limits state dropdown to unique states within a region' do
      @user = FactoryBot.create(:user, username: 'ssw', email: 'ssw@yeah.com', created_at: '02/02/2016')
      login(@user)
      chicago = FactoryBot.create(:region, name: 'chicago')

      FactoryBot.create(:location, region: @region, state: 'WA')
      FactoryBot.create(:location, region: chicago, state: 'IL')
      login

      visit "/#{@region.name}/suggest"
      expect(page).to have_select('location_state', options: [ '', 'OR', 'WA' ])
    end

    it 'does not show form if not logged in' do
      visit "/#{@region.name}/suggest"
      expect(page).to have_content('To suggest a new location you first need to login. Thank you!')
    end
  end

  describe 'Homepage', type: :feature, js: true do
    it 'shows the proper page title' do
      visit '/'

      expect(page).to have_title('Pinball Map')
      expect(page).not_to have_title('App')
    end
  end

  describe 'Pages', type: :feature, js: true do
    it 'show the proper page title' do
      FactoryBot.create(:user, id: 111)
      visit '/app'
      expect(page).to have_title('App')

      visit '/donate'
      expect(page).to have_title('Donate')

      visit '/store'
      expect(page).to have_title('Store')

      visit '/faq'
      expect(page).to have_title('FAQ')

      visit '/stats'
      expect(page).to have_title('Stats')

      visit '/users/111/profile'
      expect(page).to have_title('User Profile')

      visit "/#{@region.name}/about"
      expect(page).to have_title('About')

      visit "/#{@region.name}/suggest"
      expect(page).to have_title('Suggest')

      visit "/#{@region.name}/events"
      expect(page).to have_title('Events')

      visit "/#{@region.name}/high_rollers"
      expect(page).to have_title('High Scores')

      visit '/map/?by_location_id=1234'
      expect(page).to have_title('Pinball Map')

      visit "/map/?by_location_id=#{@location.id}"
      expect(page).to have_title("Clark's Depot")
    end
  end

  describe 'Landing page for a region', type: :feature, js: true do
    it 'shows the proper location and machine counts in the intro text' do
      chicago = FactoryBot.create(:region, name: 'chicago')
      machine = FactoryBot.create(:machine)

      FactoryBot.create(:location_machine_xref, location: @location, machine: machine)
      FactoryBot.create(:location_machine_xref, location: FactoryBot.create(:location, region: @region), machine: machine)

      FactoryBot.create(:location_machine_xref, location: FactoryBot.create(:location, region: chicago), machine: machine)

      visit '/portland'

      expect(page).to have_content('2 locations & 2 machines')
    end

    it 'shows the proper page title' do
      visit '/portland'

      expect(page).to have_title('Portland Pinball Map')
      expect(page).not_to have_title('Apps')
    end
  end

  describe 'admin', type: :feature, js: true do
    it 'presents a link to the admin pages if you are an admin' do
      visit '/'
      find('#menu_button').click

      expect(page).to_not have_content('Admin')
      expect(page).to have_content('Login')

      visit '/portland'
      find('#menu_button').click

      expect(page).to_not have_content('Admin')
      expect(page).to have_content('Login')

      user = FactoryBot.create(:user)
      login(user)

      visit '/'
      find('#menu_button').click

      expect(page).to_not have_content('Admin')
      expect(page).to have_content('Logout')

      visit '/portland'
      find('#menu_button').click

      expect(page).to_not have_content('Admin')
      expect(page).to have_content('Logout')

      user = FactoryBot.create(:user, region_id: @region.id)
      login(user)

      visit '/'
      find('#menu_button').click

      expect(page).to have_content('Admin')
      expect(page).to have_content('Logout')

      visit '/portland'
      find('#menu_button').click

      expect(page).to have_content('Admin')
      expect(page).to have_content('Logout')
    end
  end

  describe 'get_a_profile', type: :feature, js: true do
    it 'redirects you to your user profile page if you are logged in' do
      visit '/inspire_profile'

      expect(page).to have_current_path(inspire_profile_path)

      user = FactoryBot.create(:user, id: 10)
      login(user)

      visit '/inspire_profile'

      expect(page).to have_current_path(profile_user_path(user.id))
    end
  end

  describe 'activity page and filtering', type: :feature, js: true do
    before(:each) do
      @other_region_location = FactoryBot.create(:location, city: 'Hillsboro', zip: '97005', name: "Ripley's Hut", region: @other_region)
      @other_region = FactoryBot.create(:region, name: 'seattle', full_name: 'Seattle')

      FactoryBot.create(:user_submission, created_at: '2025-01-02', region: @region, region_id: @region.id, location: @location, location_name: @location.name, user_name: 'ssw', machine_name: 'Sassy Madness', submission_type: UserSubmission::NEW_LMX_TYPE)

      FactoryBot.create(:user_submission, created_at: '2025-01-02', region: @region, region_id: @region.id, location: @location, location_name: @location.name, user_name: 'ssw', machine_name: 'Sassy Madness', submission_type: UserSubmission::REMOVE_MACHINE_TYPE)

      FactoryBot.create(:user_submission, created_at: '2025-01-03', region: @other_region, region_id: @other_region.id, location: @other_region_location, location_name: @other_region_location.name, user_name: 'ssw', machine_name: 'Pizza Attack', submission_type: UserSubmission::REMOVE_MACHINE_TYPE)

      FactoryBot.create(:user_submission, created_at: '2025-01-03', region: @other_region, region_id: @other_region.id, location: @other_region_location, location_name: @other_region_location.name, user_name: 'ssw', machine_name: 'Pizza Attack', submission_type: UserSubmission::NEW_LMX_TYPE)

      FactoryBot.create(:user_submission, created_at: '2025-01-04', region: @region, region_id: @region.id, location_name: 'Doughnut Haven', user_name: 'ssw', machine_name: 'Pizza Attack', submission_type: UserSubmission::NEW_LMX_TYPE, deleted_at: '2025-01-04')
    end
    it 'shows region activity' do
      visit '/portland/activity'

      expect(page).to have_content("Here's a feed of edits to the Portland Pinball Map")
      expect(page).to have_content("added to Clark's Depot")
      expect(page).to have_content("removed from Clark's Depot")
      expect(page).to_not have_content("added to Ripley's Hut")
      expect(page).to_not have_content("removed from Ripley's Hut")
      expect(page).to have_link("Clark's Depot")
      expect(page).to_not have_content("removed from Doughtnut Haven")
    end
    it 'filters region activity' do
      visit '/portland/activity'

      find('#filterNewLmx').click
      find('.save_button').click

      expect(page).to have_content("Here's a feed of edits to the Portland Pinball Map")
      expect(page).to have_content("added to Clark's Depot")
      expect(page).to_not have_content("added to Ripley's Hut")
      expect(page).to_not have_content("removed from Ripley's Hut")
      expect(page).to_not have_content("removed from Clark's Depot")
      expect(page).to_not have_content("removed from Doughtnut Haven")
    end
    it 'shows global activity' do
      visit '/activity'

      expect(page).to have_content('Recent Activity')
      expect(page).to have_content("added to Clark's Depot")
      expect(page).to have_content("removed from Clark's Depot")
      expect(page).to have_content("added to Ripley's Hut")
      expect(page).to have_content("removed from Ripley's Hut")
      expect(page).to_not have_content("removed from Doughtnut Haven")
    end
    it 'filters activity' do
      visit '/activity'

      find('#filterNewLmx').click
      find('.save_button').click

      expect(page).to have_content("added to Clark's Depot")
      expect(page).to have_content("added to Ripley's Hut")
      expect(page).to_not have_content("removed from Ripley's Hut")
      expect(page).to_not have_content("removed from Clark's Depot")
      expect(page).to_not have_content("removed from Doughtnut Haven")
    end
  end

  describe 'activity page pagination', type: :feature, js: true do
    before(:each) do
      @other_region_location = FactoryBot.create(:location, city: 'Hillsboro', zip: '97005', name: "Ripley's Hut", region: @other_region)
      @other_region = FactoryBot.create(:region, name: 'seattle', full_name: 'Seattle')
      20.times do
        FactoryBot.create(:user_submission, created_at: '2025-01-01', region: @region, region_id: @region.id, location: @location, location_name: @location.name, user_name: 'ssw', machine_name: 'Sassy Madness', submission_type: UserSubmission::NEW_LMX_TYPE)

        FactoryBot.create(:user_submission, created_at: '2025-01-01', region: @other_region, region_id: @other_region.id, location: @other_region_location, location_name: @other_region_location.name, user_name: 'ssw', machine_name: 'Pizza Attack', submission_type: UserSubmission::NEW_LMX_TYPE)

        FactoryBot.create(:user_submission, created_at: '2025-01-02', region: @region, region_id: @region.id, location: @location, location_name: @location.name, user_name: 'ssw', machine_name: 'Sassy Madness', submission_type: UserSubmission::REMOVE_MACHINE_TYPE)

        FactoryBot.create(:user_submission, created_at: '2025-01-02', region: @other_region, region_id: @other_region.id, location: @other_region_location, location_name: @other_region_location.name, user_name: 'ssw', machine_name: 'Pizza Attack', submission_type: UserSubmission::REMOVE_MACHINE_TYPE)

        FactoryBot.create(:user_submission, created_at: '2025-01-03', region: @region, region_id: @region.id, location: @location, location_name: @location.name, user_name: 'ssw', machine_name: 'Sassy Madness', submission_type: UserSubmission::NEW_CONDITION_TYPE, comment: 'hello there')

        FactoryBot.create(:user_submission, created_at: '2025-01-03', region: @other_region, region_id: @other_region.id, location: @other_region_location, location_name: @other_region_location.name, user_name: 'ssw', machine_name: 'Pizza Attack', submission_type: UserSubmission::NEW_CONDITION_TYPE, comment: 'bye')
      end
    end
    it 'shows region pagination and respects regional results' do
      visit '/portland/activity'

      expect(page).to have_link("2")
      expect(page).to_not have_content("Pizza Attack")
    end
    it 'respects regional results on next page' do
      visit '/portland/activity'

      click_link("2")

      expect(page).to_not have_content("Pizza Attack")
    end
    it 'shows page 2 content on page 2' do
      visit '/activity'

      click_link("2")

      expect(page).to have_content("added to Clark's Depot")
      expect(page).to have_content("added to Ripley's Hut")
      expect(page).to_not have_content("bye")
      expect(page).to_not have_content("hello there")
    end
    it 'respects filter on next page' do
      20.times do
        FactoryBot.create(:user_submission, created_at: '2025-01-03', region: @region, region_id: @region.id, location: @location, location_name: @location.name, user_name: 'ssw', machine_name: 'Sassy Madness', submission_type: UserSubmission::NEW_LMX_TYPE)

        FactoryBot.create(:user_submission, created_at: '2024-12-31', region: @region, region_id: @region.id, location: @location, location_name: @location.name, user_name: 'ssw', machine_name: 'Congo', submission_type: UserSubmission::NEW_LMX_TYPE)
      end
      visit '/activity'

      find('#filterNewLmx').click
      find('.save_button').click
      click_link("2")

      expect(page).to_not have_content("removed from")
      expect(page).to have_content("Congo")
      expect(page).to have_content("added to Ripley's Hut")
      expect(page).to_not have_content("bye")
      expect(page).to_not have_content("hello there")
    end
  end
end
