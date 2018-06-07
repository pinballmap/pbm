require 'spec_helper'

describe PagesController do
  before(:each) do
    @region = FactoryBot.create(:region, name: 'portland', full_name: 'Portland')
    @location = FactoryBot.create(:location, region: @region, state: 'OR')
  end

  describe 'Regionless', type: :feature, js: true do
    it 'shouldnt perform a search if you dont enter search criteria' do
      visit '/regionless'

      click_on 'location_search_button'

      sleep 1

      expect(page.body).to have_content('NOT FOUND IN THIS REGION. PLEASE SEARCH AGAIN.')
    end

    it 'only lets you search by one thing at a time, OR address + machine' do
      visit '/regionless'

      fill_in('by_location_name', with: 'foo')

      fill_in('by_machine_name', with: 'bar')
      expect(find('#by_location_id', visible: false).value).to eq('')
      expect(find('#by_location_name').value).to eq('')
      expect(find('#address').value).to eq('')

      fill_in('address', with: 'baz')
      expect(find('#by_location_id', visible: false).value).to eq('')
      expect(find('#by_location_name').value).to eq('')
      expect(find('#by_machine_id', visible: false).value).to eq('')
      expect(find('#by_machine_name').value).to eq('bar')

      fill_in('by_machine_name', with: 'bang')
      expect(find('#by_location_id', visible: false).value).to eq('')
      expect(find('#by_location_name').value).to eq('')
      expect(find('#address').value).to eq('baz')

      fill_in('by_location_name', with: 'foo')
      expect(find('#by_machine_name').value).to eq('')
      expect(find('#address').value).to eq('')
    end

    it 'lets you search by address and machine' do
      rip_city_location = FactoryBot.create(:location, region: nil, name: 'Rip City', zip: '97203', lat: 45.590502800000, lon: -122.754940100000)
      no_way_location = FactoryBot.create(:location, region: nil, name: 'No Way', zip: '97203', lat: 45.593049200000, lon: -122.732620200000)
      FactoryBot.create(:location_machine_xref, location: rip_city_location, machine: FactoryBot.create(:machine, name: 'Sass'))
      FactoryBot.create(:location_machine_xref, location: no_way_location, machine: FactoryBot.create(:machine, name: 'Bawb'))

      visit '/regionless'

      fill_in('by_machine_name', with: 'Sass')
      page.execute_script %{ $('#by_machine_name').trigger('focus') }
      page.execute_script %{ $('#by_machine_name').trigger('keydown') }
      find(:xpath, '//li[contains(text(), "Sass")]').click

      fill_in('address', with: '97203')

      click_on 'location_search_button'

      sleep 1

      expect(page.body).to have_content('Rip City')
      expect(page.body).to_not have_content('No Way')
    end

    it 'location autocomplete select ensures you only search by a single location' do
      FactoryBot.create(:location, region: nil, name: 'Rip City Retail SW')
      FactoryBot.create(:location, region: nil, name: 'Rip City Retail', city: 'Portland', state: 'OR')

      visit '/regionless'

      fill_in('by_location_name', with: 'Rip')
      page.execute_script %{ $('#by_location_name').trigger('focus') }
      page.execute_script %{ $('#by_location_name').trigger('keydown') }
      find(:xpath, '//li[text()="Rip City Retail (Portland, OR)"]').click

      click_on 'location_search_button'

      sleep 1

      expect(find('#search_results')).to have_content('Rip City Retail')
      expect(find('#search_results')).to_not have_content('Rip City Retail SW')
    end

    it 'displays region name in location detail' do
      rip_location = FactoryBot.create(:location, region: nil, name: 'Rip City Retail SW')
      clark_location = FactoryBot.create(:location, region: FactoryBot.create(:region, name: 'Portland', full_name: 'Portland'), name: "Clark's Corner")
      renee_location = FactoryBot.create(:location, region: FactoryBot.create(:region, name: 'Chicago', full_name: 'Chicago'), name: "Renee's Rental")
      FactoryBot.create(:location_machine_xref, location: rip_location, machine: FactoryBot.create(:machine, name: 'Sass'))
      FactoryBot.create(:location_machine_xref, location: clark_location, machine: FactoryBot.create(:machine, name: 'Sass 2'))
      FactoryBot.create(:location_machine_xref, location: renee_location, machine: FactoryBot.create(:machine, name: 'Sass 3'))

      visit '/regionless'

      fill_in('by_machine_name', with: 'Sass')
      click_on 'location_search_button'
      expect(find('#search_results')).to_not have_content('Region:')

      fill_in('by_machine_name', with: 'Sass 2')
      click_on 'location_search_button'
      expect(find('#search_results')).to have_content('Region: Portland')

      fill_in('by_machine_name', with: 'Sass 3')
      click_on 'location_search_button'
      expect(find('#search_results')).to have_content('Region: Chicago')
    end

    it 'machine search blanks out machine_id when you search, honors machine_name scope' do
      rip_location = FactoryBot.create(:location, region: nil, name: 'Rip City Retail SW')
      clark_location = FactoryBot.create(:location, region: nil, name: "Clark's Corner")
      renee_location = FactoryBot.create(:location, region: nil, name: "Renee's Rental")
      FactoryBot.create(:location_machine_xref, location: rip_location, machine: FactoryBot.create(:machine, name: 'Sass'))
      FactoryBot.create(:location_machine_xref, location: clark_location, machine: FactoryBot.create(:machine, name: 'Sass 2'))
      FactoryBot.create(:location_machine_xref, location: renee_location, machine: FactoryBot.create(:machine, name: 'Bawb'))

      visit '/regionless'

      fill_in('by_machine_name', with: 'Bawb')
      page.execute_script %{ $('#by_machine_name').trigger('focus') }
      page.execute_script %{ $('#by_machine_name').trigger('keydown') }
      find(:xpath, '//li[text()="Bawb"]').click

      click_on 'location_search_button'

      sleep 1

      expect(find('#search_results')).to have_content('Renee')
      expect(find('#search_results')).to_not have_content('Clark')
      expect(find('#search_results')).to_not have_content('Rip City')

      fill_in('by_machine_name', with: 'Sass')

      click_on 'location_search_button'

      sleep 1

      expect(find('#search_results')).to have_content('Rip City')
      expect(find('#search_results')).to_not have_content('Clark')
      expect(find('#search_results')).to_not have_content('Renee')
    end
  end

  describe 'Events', type: :feature, js: true do
    it 'handles basic event displaying' do
      FactoryBot.create(:event, region: @region, location: @location, name: 'event 1', start_date: Date.today)
      FactoryBot.create(:event, region: @region, location: @location, name: 'event 2', start_date: Date.today + 1)
      FactoryBot.create(:event, region: @region, location: @location, name: 'event 3', start_date: Date.today - 1)
      FactoryBot.create(:event, region: @region, location: @location, name: 'event 4')
      FactoryBot.create(:event, region: @region, location: @location, external_location_name: 'External location', name: 'event 5')
      FactoryBot.create(:event, region: @region, external_location_name: 'External location', name: 'event 6')

      visit '/portland/events'

      expect(page).to have_content("event 3 @ Test Location Name #{Date.today.strftime('%b-%d-%Y')}")
      expect(page).to have_content("event 1 @ Test Location Name #{(Date.today + 1).strftime('%b-%d-%Y')}")
      expect(page).to have_content('event 2 @ Test Location Name')
    end

    it 'is case insensitive for region name' do
      chicago_region = FactoryBot.create(:region, name: 'chicago', full_name: 'Chicago')
      FactoryBot.create(:event, region: chicago_region, name: 'event 1', start_date: Date.today)

      visit '/CHICAGO/events'

      expect(page).to have_content('event 1')
    end

    it 'does not display events that are a week older than their end date' do
      FactoryBot.create(:event, region: @region, location: @location, name: 'event 1', start_date: Date.today, end_date: Date.today)
      FactoryBot.create(:event, region: @region, location: @location, name: 'event 2', start_date: Date.today - 8, end_date: Date.today - 8)

      visit '/portland/events'

      expect(page).to have_content('event 1')
      expect(page).to_not have_content('event 2')
    end

    it 'does not display events that are a week older than start date if there is no end date' do
      FactoryBot.create(:event, region: @region, location: @location, name: 'event 1', start_date: Date.today)
      FactoryBot.create(:event, region: @region, location: @location, name: 'event 2', start_date: Date.today - 8)

      visit '/portland/events'

      expect(page).to have_content('event 1')
      expect(page).to_not have_content('event 2')
    end

    it 'displays events that have no start/end date (typically league stuff)' do
      FactoryBot.create(:event, region: @region, location: @location, name: 'event 1', start_date: nil, end_date: nil)
      FactoryBot.create(:event, region: @region, location: @location, name: 'event 2', start_date: Date.today)

      visit '/portland/events'

      expect(page).to have_content('event 1')
      expect(page).to have_content('event 2')
    end
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

      expect(page).to have_content('Machine10: with 10 machines Machine9: with 9 machines Machine8: with 8 machines Machine7: with 7 machines Machine6: with 6 machines Machine5: with 5 machines Machine4: with 4 machines Machine3: with 3 machines Machine2: with 2 machines Machine1: with 1 machines')
    end
  end

  describe 'Links', type: :feature, js: true do
    it 'shows links in a region' do
      chicago = FactoryBot.create(:region, name: 'chicago', full_name: 'Chicago')

      FactoryBot.create(:region_link_xref, region: @region, description: 'foo')
      FactoryBot.create(:region_link_xref, region: chicago, name: 'chicago link 1', category: 'main links', sort_order: 2, description: 'desc1')
      FactoryBot.create(:region_link_xref, region: chicago, name: 'cool link 1', category: 'cool links', sort_order: 1, description: 'desc2')

      visit '/chicago/about'

      expect(page).to have_content('cool links cool link 1 desc2 main links chicago link 1 desc1')
    end

    it 'sort order does not cause headers to display twice' do
      FactoryBot.create(:region_link_xref, region: @region, description: 'desc', name: 'link 1', category: 'main links', sort_order: 2)
      FactoryBot.create(:region_link_xref, region: @region, description: 'desc', name: 'link 2', category: 'main links', sort_order: 1)
      FactoryBot.create(:region_link_xref, region: @region, description: 'desc', name: 'link 3', category: 'other category')

      visit "/#{@region.name}/about"

      expect(page).to have_content('main links link 2 desc link 1 desc other category link 3 desc')
    end

    it 'makes a default link category called "Links"' do
      FactoryBot.create(:region_link_xref, region: @region, name: 'link 1', description: nil, category: nil)
      FactoryBot.create(:region_link_xref, region: @region, name: 'link 2', description: nil, category: '')
      FactoryBot.create(:region_link_xref, region: @region, name: 'link 3', description: nil, category: ' ')
      FactoryBot.create(:region_link_xref, region: @region, name: 'link 4', description: nil, category: 'other category')

      visit "/#{@region.name}/about"

      expect(page).to have_content('Links link 1 link 2 link 3 other category link 4')
    end

    it 'Mixing sort_order and nil sort_order links does not error' do
      FactoryBot.create(:region_link_xref, region: @region, name: 'Minnesota Pinball - The "Pin Cities"', url: 'https://www.facebook.com/groups/minnesotapinball/', description: 'Your best source for everything pinball in Minnesota!  Events, leagues, locations, games and more!', category: 'Pinball Map Links', sort_order: 1)
      FactoryBot.create(:region_link_xref, region: @region, name: 'Pinball Map Store', url: 'http://blog.pinballmap.com', description: 'News, questions, feelings.', category: 'Pinball Map Links', sort_order: nil)

      visit "/#{@region.name}/about"

      expect(page).to have_content('Links Pinball Map Store News, questions, feelings. Minnesota Pinball - The "Pin Cities" Your best source for everything pinball in Minnesota! Events, leagues, locations, games and more!')
    end
  end

  describe 'Location suggestions', type: :feature, js: true do
    it 'limits state dropdown to unique states within a region' do
      @user = FactoryBot.create(:user, username: 'ssw', email: 'ssw@yeah.com', created_at: '02/02/2016')
      page.set_rack_session("warden.user.user.key": User.serialize_into_session(@user))
      chicago = FactoryBot.create(:region, name: 'chicago')

      FactoryBot.create(:location, region: @region, state: 'WA')
      FactoryBot.create(:location, region: chicago, state: 'IL')
      login

      visit "/#{@region.name}/suggest"
      expect(page).to have_select('location_state', options: %w[OR WA])
    end

    it 'does not show form if not logged in' do
      visit "/#{@region.name}/suggest"
      expect(page).to have_content('But first! We ask that you Login. Thank you!')
    end
  end

  describe 'Homepage', type: :feature, js: true do
    it 'shows the proper number of locations and machines per region' do
      chicago = FactoryBot.create(:region, name: 'chicago', full_name: 'Chicago')
      machine = FactoryBot.create(:machine)

      FactoryBot.create(:location_machine_xref, location: @location, machine: machine)
      FactoryBot.create(:location_machine_xref, location: FactoryBot.create(:location, region: @region), machine: machine)

      FactoryBot.create(:location_machine_xref, location: FactoryBot.create(:location, region: chicago), machine: machine)

      visit '/'

      expect(page).to have_css('div#region_list')
      expect(page).to have_content('Chicago 1 Locations 1 Machines Portland 2 Locations 2 Machines')
    end

    it 'shows the proper page title' do
      visit '/'

      expect(page).to have_title('Pinball Map')
      expect(page).not_to have_title('App')
    end

    it 'does not show a random location link if there are no locations in the region' do
      toronto = FactoryBot.create(:region, name: 'toronto', full_name: 'Toronto')

      visit '/toronto'

      expect(page).not_to have_content('Or click here for a random location!')

      FactoryBot.create(:location, region: toronto)

      visit '/toronto'

      expect(page).to have_content('Or click here for a random location!')
    end
  end

  describe 'Pages', type: :feature, js: true do
    it 'show the proper page title' do
      FactoryBot.create(:user, id: 111)
      visit '/app'
      expect(page).to have_title('App')

      visit '/app/support'
      expect(page).to have_title('App')

      visit '/donate'
      expect(page).to have_title('Donate')

      visit '/store'
      expect(page).to have_title('Store')

      visit '/faq'
      expect(page).to have_title('FAQ')

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

      expect(page).to have_content('2 locations and 2 machines')
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

      expect(page).to_not have_content('Admin')
      expect(page).to have_content('Login')

      visit '/portland'

      expect(page).to_not have_content('Admin')
      expect(page).to have_content('Login')

      user = FactoryBot.create(:user)
      page.set_rack_session("warden.user.user.key": User.serialize_into_session(user))

      visit '/'

      expect(page).to_not have_content('Admin')
      expect(page).to have_content('Logout')

      visit '/portland'

      expect(page).to_not have_content('Admin')
      expect(page).to have_content('Logout')

      user = FactoryBot.create(:user, region_id: @region.id)
      page.set_rack_session("warden.user.user.key": User.serialize_into_session(user))

      visit '/'

      expect(page).to have_content('Admin')
      expect(page).to have_content('Logout')

      visit '/portland'

      expect(page).to have_content('Admin')
      expect(page).to have_content('Logout')
    end
  end

  describe 'get_a_profile', type: :feature, js: true do
    it 'redirects you to your user profile page if you are logged in' do
      visit '/inspire_profile'

      expect(current_path).to eql(inspire_profile_path)

      user = FactoryBot.create(:user, id: 10)
      page.set_rack_session("warden.user.user.key": User.serialize_into_session(user))

      visit '/inspire_profile'

      expect(current_path).to eql(profile_user_path(user.id))
    end
  end
end
