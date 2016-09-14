require 'spec_helper'

describe PagesController do
  before(:each) do
    @region = FactoryGirl.create(:region, name: 'portland', full_name: 'Portland')
    @location = FactoryGirl.create(:location, region: @region, state: 'OR')
  end

  describe 'Events', type: :feature, js: true do
    it 'handles basic event displaying' do
      FactoryGirl.create(:event, region: @region, location: @location, name: 'event 1', start_date: Date.today)
      FactoryGirl.create(:event, region: @region, location: @location, name: 'event 2', start_date: Date.today + 1)
      FactoryGirl.create(:event, region: @region, location: @location, name: 'event 3', start_date: Date.today - 1)
      FactoryGirl.create(:event, region: @region, location: @location, name: 'event 4')
      FactoryGirl.create(:event, region: @region, location: @location, external_location_name: 'External location', name: 'event 5')
      FactoryGirl.create(:event, region: @region, external_location_name: 'External location', name: 'event 6')

      visit '/portland/events'

      expect(page).to have_content("event 3 @ Test Location Name #{Date.today.strftime('%b-%d-%Y')}")
      expect(page).to have_content("event 1 @ Test Location Name #{(Date.today + 1).strftime('%b-%d-%Y')}")
      expect(page).to have_content('event 2 @ Test Location Name')
    end

    it 'is case insensitive for region name' do
      chicago_region = FactoryGirl.create(:region, name: 'chicago', full_name: 'Chicago')
      FactoryGirl.create(:event, region: chicago_region, name: 'event 1', start_date: Date.today)

      visit '/CHICAGO/events'

      expect(page).to have_content('event 1')
    end

    it 'does not display events that are a week older than their end date' do
      FactoryGirl.create(:event, region: @region, location: @location, name: 'event 1', start_date: Date.today, end_date: Date.today)
      FactoryGirl.create(:event, region: @region, location: @location, name: 'event 2', start_date: Date.today - 8, end_date: Date.today - 8)

      visit '/portland/events'

      expect(page).to have_content('event 1')
      expect(page).to_not have_content('event 2')
    end

    it 'does not display events that are a week older than start date if there is no end date' do
      FactoryGirl.create(:event, region: @region, location: @location, name: 'event 1', start_date: Date.today)
      FactoryGirl.create(:event, region: @region, location: @location, name: 'event 2', start_date: Date.today - 8)

      visit '/portland/events'

      expect(page).to have_content('event 1')
      expect(page).to_not have_content('event 2')
    end
  end

  describe 'High roller list', type: :feature, js: true do
    it 'should have intro text that displays correct number of locations and machines for a region' do
      chicago_region = FactoryGirl.create(:region, name: 'chicago')
      portland_location = FactoryGirl.create(:location, region: @region)
      chicago_location = FactoryGirl.create(:location, region: chicago_region)

      machine = FactoryGirl.create(:machine)

      portland_lmx = FactoryGirl.create(:location_machine_xref, location: @location, machine: machine)
      another_portland_lmx = FactoryGirl.create(:location_machine_xref, location: portland_location, machine: machine)
      FactoryGirl.create(:location_machine_xref, location: chicago_location, machine: machine)

      ssw_user = FactoryGirl.create(:user, username: 'ssw')
      rtgt_user = FactoryGirl.create(:user, username: 'rtgt')
      FactoryGirl.create(:machine_score_xref, location_machine_xref: portland_lmx, score: 100, user: ssw_user)
      FactoryGirl.create(:machine_score_xref, location_machine_xref: portland_lmx, score: 90, user: rtgt_user)
      FactoryGirl.create(:machine_score_xref, location_machine_xref: another_portland_lmx, score: 200, user: ssw_user)

      visit '/portland/high_rollers'

      expect(page).to have_content('ssw: with 2 scores')
      expect(page).to have_content('rtgt: with 1 scores')
    end
  end

  describe 'Top 10 Machine Counts', type: :feature, js: true do
    it 'shows the top 10 machine counts on the about page' do
      11.times do |machine_name_counter|
        machine_name_counter.times do
          FactoryGirl.create(:location_machine_xref, location: @location, machine: Machine.where(name: "Machine#{machine_name_counter}").first_or_create)
        end
      end

      visit '/portland/about'

      expect(page).to have_content('Machine10: with 10 machines Machine9: with 9 machines Machine8: with 8 machines Machine7: with 7 machines Machine6: with 6 machines Machine5: with 5 machines Machine4: with 4 machines Machine3: with 3 machines Machine2: with 2 machines Machine1: with 1 machines')
    end
  end

  describe 'Links', type: :feature, js: true do
    it 'shows links in a region' do
      chicago = FactoryGirl.create(:region, name: 'chicago', full_name: 'Chicago')

      FactoryGirl.create(:region_link_xref, region: @region, description: 'foo')
      FactoryGirl.create(:region_link_xref, region: chicago, name: 'chicago link 1', category: 'main links', sort_order: 2, description: 'desc1')
      FactoryGirl.create(:region_link_xref, region: chicago, name: 'cool link 1', category: 'cool links', sort_order: 1, description: 'desc2')

      visit '/chicago/about'

      expect(page).to have_content('cool links cool link 1 desc2 main links chicago link 1 desc1')
    end

    it 'sort order does not cause headers to display twice' do
      FactoryGirl.create(:region_link_xref, region: @region, description: 'desc', name: 'link 1', category: 'main links', sort_order: 2)
      FactoryGirl.create(:region_link_xref, region: @region, description: 'desc', name: 'link 2', category: 'main links', sort_order: 1)
      FactoryGirl.create(:region_link_xref, region: @region, description: 'desc', name: 'link 3', category: 'other category')

      visit "/#{@region.name}/about"

      expect(page).to have_content('main links link 2 desc link 1 desc other category link 3 desc')
    end

    it 'makes a default link category called "Links"' do
      FactoryGirl.create(:region_link_xref, region: @region, name: 'link 1', description: nil, category: nil)
      FactoryGirl.create(:region_link_xref, region: @region, name: 'link 2', description: nil, category: '')
      FactoryGirl.create(:region_link_xref, region: @region, name: 'link 3', description: nil, category: ' ')
      FactoryGirl.create(:region_link_xref, region: @region, name: 'link 4', description: nil, category: 'other category')

      visit "/#{@region.name}/about"

      expect(page).to have_content('Links link 1 link 2 link 3 other category link 4')
    end

    it 'Mixing sort_order and nil sort_order links does not error' do
      FactoryGirl.create(:region_link_xref, region: @region, name: 'Minnesota Pinball - The "Pin Cities"', url: 'https://www.facebook.com/groups/minnesotapinball/', description: 'Your best source for everything pinball in Minnesota!  Events, leagues, locations, games and more!', category: 'Pinball Map Links', sort_order: 1)
      FactoryGirl.create(:region_link_xref, region: @region, name: 'Pinball Map Store', url: 'http://blog.pinballmap.com', description: 'News, questions, feelings.', category: 'Pinball Map Links', sort_order: nil)

      visit "/#{@region.name}/about"

      expect(page).to have_content('Links Pinball Map Store News, questions, feelings. Minnesota Pinball - The "Pin Cities" Your best source for everything pinball in Minnesota! Events, leagues, locations, games and more!')
    end
  end

  describe 'Location suggestions', type: :feature, js: true do
    it 'limits state dropdown to unique states within a region' do
      chicago = FactoryGirl.create(:region, name: 'chicago')

      FactoryGirl.create(:location, region: @region, state: 'WA')
      FactoryGirl.create(:location, region: chicago, state: 'IL')

      visit "/#{@region.name}/suggest"

      expect(page).to have_select('location_state', options: %w(OR WA))
    end
  end

  describe 'Homepage', type: :feature, js: true do
    it 'shows the proper number of locations and machines per region' do
      chicago = FactoryGirl.create(:region, name: 'chicago', full_name: 'Chicago')
      machine = FactoryGirl.create(:machine)

      FactoryGirl.create(:location_machine_xref, location: @location, machine: machine)
      FactoryGirl.create(:location_machine_xref, location: FactoryGirl.create(:location, region: @region), machine: machine)

      FactoryGirl.create(:location_machine_xref, location: FactoryGirl.create(:location, region: chicago), machine: machine)

      visit '/'

      expect(page).to have_css('div#map_summaries')
      expect(page).to have_content('Chicago 1 Locations 1 Machines Portland 2 Locations 2 Machines')
    end

    it 'shows the proper page title' do

      visit '/'

      expect(page).to have_title('Pinball Map')
      expect(page).not_to have_title('App')
    end
  end

  describe 'Pages', type: :feature, js: true do
    it 'show the proper page title' do

      visit '/apps'
      expect(page).to have_title('App')

      visit '/apps/support'
      expect(page).to have_title('App')

      visit '/donate'
      expect(page).to have_title('Donate to')

      visit '/store'
      expect(page).to have_title('Store')

      visit '/faq'
      expect(page).to have_title('FAQ')

      visit "/#{@region.name}/about"
      expect(page).to have_title('About')

      visit "/#{@region.name}/suggest"
      expect(page).to have_title('Suggest')

      visit "/#{@region.name}/events"
      expect(page).to have_title('Events')

      visit "/#{@region.name}/high_rollers"
      expect(page).to have_title('High Scores')
    end
  end

  describe 'Landing page for a region', type: :feature, js: true do
    it 'shows the proper location and machine counts in the intro text' do
      chicago = FactoryGirl.create(:region, name: 'chicago')
      machine = FactoryGirl.create(:machine)

      FactoryGirl.create(:location_machine_xref, location: @location, machine: machine)
      FactoryGirl.create(:location_machine_xref, location: FactoryGirl.create(:location, region: @region), machine: machine)

      FactoryGirl.create(:location_machine_xref, location: FactoryGirl.create(:location, region: chicago), machine: machine)

      visit '/portland'

      expect(page).to have_content('2 locations and 2 machines')
    end

    it 'shows the proper page title' do

      visit '/portland'

      expect(page).to have_title('Portland Pinball Map')
      expect(page).not_to have_title('Apps')
    end
  end

  describe 'User profile', type: :feature, js: true do
    it 'display metrics about the users account' do
      @user = FactoryGirl.create(:user, username: 'ssw', email: 'ssw@yeah.com', created_at: '02/02/2016')
      page.set_rack_session('warden.user.user.key' => User.serialize_into_session(@user).unshift('User'))

      FactoryGirl.create(:user_submission, user: @user, location: FactoryGirl.create(:location, id: 100), submission_type: UserSubmission::NEW_LMX_TYPE)
      FactoryGirl.create(:user_submission, user: @user, location: Location.find(100), submission_type: UserSubmission::NEW_CONDITION_TYPE)
      FactoryGirl.create(:user_submission, user: @user, location: FactoryGirl.create(:location, id: 200), submission_type: UserSubmission::REMOVE_MACHINE_TYPE)
      FactoryGirl.create(:user_submission, user: @user, location: FactoryGirl.create(:location, id: 300), submission_type: UserSubmission::REMOVE_MACHINE_TYPE)
      FactoryGirl.create(:user_submission, user: @user, submission_type: UserSubmission::SUGGEST_LOCATION_TYPE)
      FactoryGirl.create(:user_submission, user: @user, submission_type: UserSubmission::SUGGEST_LOCATION_TYPE)
      FactoryGirl.create(:user_submission, user: @user, submission_type: UserSubmission::SUGGEST_LOCATION_TYPE)
      FactoryGirl.create(:user_submission, user: @user, location: FactoryGirl.create(:location, id: 400), submission_type: UserSubmission::LOCATION_METADATA_TYPE)
      FactoryGirl.create(:user_submission, user: @user, location: FactoryGirl.create(:location, id: 500, name: 'Location One'), machine: FactoryGirl.create(:machine, name: 'Machine One'), submission_type: UserSubmission::NEW_SCORE_TYPE, submission: 'ssw added a score of 1 for Machine One to Location One', created_at: '2016-01-02')

      FactoryGirl.create(:user_submission, user: @user, location: Location.find(400), submission_type: UserSubmission::LOCATION_METADATA_TYPE)
      FactoryGirl.create(:user_submission, user: @user, location: Location.find(500), machine: FactoryGirl.create(:machine, name: 'Machine Two'), submission_type: UserSubmission::NEW_SCORE_TYPE, submission: 'ssw added a score of 2 for Machine Two to Location One', created_at: '2016-01-01')

      login
      visit '/profile'

      expect(page).to have_content('ssw')
      expect(page).to have_content('Member since: Feb-02-2016')
      expect(page).to have_content('1 Machines Added')
      expect(page).to have_content('2 Machines Removed')
      expect(page).to have_content('1 Conditions Left')
      expect(page).to have_content('3 Locations Suggested')
      expect(page).to have_content('5 Locations Edited')
      expect(page).to have_content('High Scores: Machine Two 2 at Location One on Jan-01-2016 Machine One 1 at Location One on Jan-02-2016')
    end
  end
end
