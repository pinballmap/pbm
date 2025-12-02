require 'spec_helper'

describe MapsController do
  before(:each) do
    @region = FactoryBot.create(:region, name: 'portland', full_name: 'Portland')
    @location = FactoryBot.create(:location, region: @region, state: 'OR')
  end

  describe 'Regionless', type: :feature, js: true do
    it 'should perform a search on initial load' do
      visit '/map'

      sleep 1

      expect(page).to have_selector("#search_results")
      expect(page.body).to have_css('#intro_container', visible: true)
    end
    it 'should perform a search with no search criteria' do
      visit '/map'

      click_on 'location_search_button'

      sleep 1

      expect(page).to have_selector("#search_results")
      expect(page.body).to have_css('#intro_container', visible: false)
    end

    it 'only lets you search by one thing at a time, OR address + machine' do
      visit '/map'

      fill_in('by_location_name', with: 'foo')

      fill_in('by_machine_name', with: 'bar')
      expect(find('#by_location_id', visible: :hidden).value).to eq('')
      expect(find('#by_location_name').value).to eq('')
      expect(find('#address').value).to eq('')
      expect(find('#by_city_name', visible: :hidden).value).to eq('')
      expect(find('#by_state_name', visible: :hidden).value).to eq('')
      expect(find('#by_city_no_state', visible: :hidden).value).to eq('')

      fill_in('address', with: 'baz')
      expect(find('#by_location_id', visible: :hidden).value).to eq('')
      expect(find('#by_location_name').value).to eq('')
      expect(find('#by_machine_id', visible: :hidden).value).to eq('')
      expect(find('#by_machine_name').value).to eq('bar')

      fill_in('by_machine_name', with: 'bang')
      expect(find('#by_location_id', visible: :hidden).value).to eq('')
      expect(find('#by_location_name').value).to eq('')
      expect(find('#address').value).to eq('baz')

      fill_in('by_location_name', with: 'foo')
      expect(find('#by_machine_name').value).to eq('')
      expect(find('#address').value).to eq('')
      expect(find('#by_city_name', visible: :hidden).value).to eq('')
      expect(find('#by_state_name', visible: :hidden).value).to eq('')
      expect(find('#by_city_no_state', visible: :hidden).value).to eq('')
    end

    it 'lets you search by address and machine and respects if you change or clear out the machine search value' do
      rip_city_location = FactoryBot.create(:location, region: nil, name: 'Rip City', zip: '97203', lat: 45.590502800000, lon: -122.754940100000)
      no_way_location = FactoryBot.create(:location, region: nil, name: 'No Way', zip: '97203', lat: 45.593049200000, lon: -122.732620200000)
      FactoryBot.create(:location, region: nil, name: 'Far Off', city: 'Seattle', state: 'WA', zip: '98121', lat: 47.61307324803172, lon: -122.34479886878611)
      FactoryBot.create(:location_machine_xref, location: rip_city_location, machine: FactoryBot.create(:machine, name: 'Sass Pro'))
      FactoryBot.create(:location_machine_xref, location: no_way_location, machine: FactoryBot.create(:machine, name: 'Bawb Premium'))

      visit '/map'

      fill_in('by_machine_name', with: 'Sass Pro')
      page.execute_script %{ $('#by_machine_name').trigger('focus') }
      page.execute_script %{ $('#by_machine_name').trigger('keydown') }
      find(:xpath, '//div[contains(text(), "Sass Pro")]').click

      fill_in('address', with: '97203')

      click_on 'location_search_button'

      sleep 1

      expect(find('#search_results')).to have_content('Rip City')
      expect(find('#search_results')).to_not have_content('No Way')
      expect(page.body).to have_css('#intro_container', visible: false)

      fill_in('by_machine_name', with: 'Bawb Premium')
      page.execute_script %{ $('#by_machine_name').trigger('focus') }
      page.execute_script %{ $('#by_machine_name').trigger('keydown') }
      find(:xpath, '//div[contains(text(), "Bawb Premium")]').click

      fill_in('address', with: '97203')

      click_on 'location_search_button'

      sleep 1

      expect(find('#search_results')).to_not have_content('Rip City')
      expect(find('#search_results')).to have_content('No Way')

      fill_in('by_machine_name', with: '')

      fill_in('address', with: '97203')

      click_on 'location_search_button'

      sleep 1

      expect(find('#search_results')).to have_content('Rip City')
      expect(find('#search_results')).to have_content('No Way')

      fill_in('address', with: 'Seattle')
      page.execute_script %{ $('#address').trigger('focus') }
      page.execute_script %{ $('#address').trigger('keydown') }
      find(:xpath, '//div[contains(text(), "Seattle, WA")]').click

      click_on 'location_search_button'

      sleep 0.5

      expect(find('#search_results')).to have_content('Far Off')

      fill_in('address', with: '97203')

      click_on 'location_search_button'

      sleep 1

      expect(find('#search_results')).to have_content('Rip City')
      expect(find('#search_results')).to have_content('No Way')
    end

    it 'lets you clear search input values with the clearButton x and starts a fresh search' do
      # this test needs work. It was not failing when the function was broken.
      rip_city_location = FactoryBot.create(:location, region: nil, name: 'Rip City', zip: '97203', lat: 45.590502800000, lon: -122.754940100000)
      no_way_location = FactoryBot.create(:location, region: nil, name: 'No Way', zip: '97203', lat: 45.593049200000, lon: -122.732620200000)
      FactoryBot.create(:location, region: nil, name: 'Far Off', city: 'Seattle', state: 'WA', zip: '98121', lat: 47.61307324803172, lon: -122.34479886878611)
      FactoryBot.create(:location_machine_xref, location: rip_city_location, machine: FactoryBot.create(:machine, name: 'Sass Pro'))
      FactoryBot.create(:location_machine_xref, location: no_way_location, machine: FactoryBot.create(:machine, name: 'Bawb Premium'))

      visit '/map'

      fill_in('by_location_name', with: 'Rip City')
      page.execute_script %{ $('#by_machine_name').trigger('focus') }
      page.execute_script %{ $('#by_machine_name').trigger('keydown') }
      find(:xpath, '//div[contains(text(), "Rip City")]').click

      click_on 'location_search_button'

      sleep 0.5

      expect(find('#search_results')).to have_content('Rip City')
      expect(find('#search_results')).to_not have_content('No Way')
      expect(find('#search_results')).to_not have_content('Far Off')

      page.find('#clearButton3').click

      click_on 'location_search_button'

      sleep 1

      expect(find('#search_results')).to have_content('Rip City')
      expect(find('#search_results')).to have_content('No Way')
      expect(find('#search_results')).to have_content('Far Off')
    end

    it 'lets you filter by location type and number of machines with address and machine name' do
      bar_type = FactoryBot.create(:location_type, id: 4, name: 'bar')
      cleo = FactoryBot.create(:location, id: 38, zip: '97203', lat: 45.590502800000, lon: -122.754940100000, name: 'Cleo', location_type: bar_type)
      bawb = FactoryBot.create(:location, id: 39, zip: '97203', lat: 45.593049200000, lon: -122.732620200000, name: 'Bawb')
      sass = FactoryBot.create(:location, id: 40, zip: '97203', lat: 45.593049200000, lon: -122.732620200000, name: 'Sass', location_type: bar_type)
      FactoryBot.create(:location_machine_xref, location: sass, machine: FactoryBot.create(:machine, name: 'Solomon', machine_group: nil))

      5.times do |index|
        FactoryBot.create(:location_machine_xref, machine: FactoryBot.create(:machine, id: 1111 + index, name: 'machine ' + index.to_s), location: cleo)
      end

      25.times do |index|
        FactoryBot.create(:location_machine_xref, machine: FactoryBot.create(:machine, id: 2222 + index, name: 'machine ' + index.to_s), location: sass)
      end

      visit '/map'

      sleep 1

      fill_in('address', with: '97203')

      page.find('#form .limit select#by_type_id').click
      select('bar', from: 'by_type_id')

      click_on 'location_search_button'

      sleep 1

      expect(page).to have_content('Cleo')
      expect(page).to_not have_content('Bawb')
      expect(page).to have_content('Sass')

      visit '/map'

      sleep 1

      fill_in('address', with: '97203')

      page.find('#form .limit select#by_at_least_n_machines').click
      select('10+', from: 'by_at_least_n_machines')

      click_on 'location_search_button'

      sleep 1

      expect(page).to_not have_content('Cleo')
      expect(page).to_not have_content('Bawb')
      expect(page).to have_content('Sass')

      visit '/map'

      sleep 1

      fill_in('by_machine_name', with: 'Solomon')
      page.execute_script %{ $('#by_machine_name').trigger('focus') }
      page.execute_script %{ $('#by_machine_name').trigger('keydown') }
      find(:xpath, '//div[contains(text(), "Solomon")]').click

      page.find('#form .limit select#by_type_id').click
      select('bar', from: 'by_type_id')

      page.find('#form .limit select#by_at_least_n_machines').click
      select('10+', from: 'by_at_least_n_machines')

      click_on 'location_search_button'

      sleep 1

      expect(page).to_not have_content('Cleo')
      expect(page).to_not have_content('Bawb')
      expect(page).to have_content('Sass')

      visit '/map'

      sleep 1

      page.find('#form .limit select#by_type_id').click
      select('bar', from: 'by_type_id')

      page.find('#form .limit select#by_at_least_n_machines').click
      select('10+', from: 'by_at_least_n_machines')

      click_on 'location_search_button'

      sleep 1

      expect(page).to_not have_content('Cleo')
      expect(page).to_not have_content('Bawb')
      expect(page).to have_content('Sass')

      visit '/map?by_type_id=4'

      sleep 1

      expect(page).to have_content('Cleo')
      expect(page).to_not have_content('Bawb')
      expect(page).to have_content('Sass')

      visit '/map?by_at_least_n_machines=5'

      sleep 1

      expect(page).to have_content('Cleo')
      expect(page).to_not have_content('Bawb')
      expect(page).to have_content('Sass')
    end

    it 'shows single version checkbox if machine is in a group and respects single version filter' do
      @machine_group = FactoryBot.create(:machine_group)
      rip_city_location = FactoryBot.create(:location, region: nil, name: 'Rip City', zip: '97203', lat: 45.590502800000, lon: -122.754940100000)
      rose_city_location = FactoryBot.create(:location, region: nil, name: 'Rose City', zip: '97203', lat: 45.590502800000, lon: -122.754940100000)
      FactoryBot.create(:location_machine_xref, location: rip_city_location, machine: FactoryBot.create(:machine, name: 'Sass', machine_group: nil))
      FactoryBot.create(:location_machine_xref, location: rip_city_location, machine: FactoryBot.create(:machine, name: 'Dude Pro', machine_group: @machine_group))
      FactoryBot.create(:location_machine_xref, location: rose_city_location, machine: FactoryBot.create(:machine, name: 'Dude Plus', machine_group: @machine_group))

      visit '/map'

      fill_in('by_machine_name', with: 'Sass')
      page.execute_script %{ $('#by_machine_name').trigger('focus') }
      page.execute_script %{ $('#by_machine_name').trigger('keydown') }
      find(:xpath, '//div[contains(text(), "Sass")]').click

      sleep 1

      expect(page.body).to have_css('#single_hide', visible: false)

      visit '/map'

      fill_in('by_machine_name', with: 'Dude Pro')
      page.execute_script %{ $('#by_machine_name').trigger('focus') }
      page.execute_script %{ $('#by_machine_name').trigger('keydown') }
      find(:xpath, '//div[contains(text(), "Dude Pro")]').click

      expect(page.body).to have_content('Exact machine version?')
      expect(page.body).to have_css('#singleVersion', visible: true)

      click_on 'location_search_button'

      sleep 1

      expect(find('#search_results')).to have_content('Rip')
      expect(find('#search_results')).to have_content('Rose')

      check 'singleVersion'

      click_on 'location_search_button'

      sleep 1

      expect(find('#search_results')).to have_content('Rip')
      expect(find('#search_results')).to_not have_content('Rose')
    end

    it 'respects user_faved filter' do
      user = FactoryBot.create(:user)
      login(user)

      FactoryBot.create(:user_fave_location, user: user, location: FactoryBot.create(:location, name: 'Foo'))
      FactoryBot.create(:user_fave_location, user: user, location: FactoryBot.create(:location, name: 'Bar'))
      FactoryBot.create(:user_fave_location, location: FactoryBot.create(:location, name: 'Baz'))

      visit '/saved'
      sleep 1

      expect(page.body).to have_content('Foo')
      expect(page.body).to have_content('Bar')
      expect(page.body).to_not have_content('Baz')
    end

    it 'lets you search by address -- displays "Not Found" if no results' do
      FactoryBot.create(:location, region: nil, name: 'Troy', zip: '48098', lat: 42.5925, lon: 83.1756)

      visit '/map'

      fill_in('address', with: '97203')

      click_on 'location_search_button'

      sleep 1

      expect(page).to have_content("NOT FOUND. PLEASE SEARCH AGAIN.\nUse the dropdown or the autocompleting textbox if you want results.")
    end

    it 'location autocomplete select ensures you only search by a single location' do
      FactoryBot.create(:location, region: nil, name: 'Rip City Retail SW')
      FactoryBot.create(:location, region: nil, name: 'Rip City Retail', city: 'Portland', state: 'OR')

      visit '/map'

      sleep 1

      fill_in('by_location_name', with: 'Rip')
      page.execute_script %{ $('#by_location_name').trigger('focus') }
      page.execute_script %{ $('#by_location_name').trigger('keydown') }
      find(:xpath, '//div[text()="Rip City Retail (Portland, OR)"]').click

      click_on 'location_search_button'

      sleep 1

      expect(find('#search_results')).to have_content('Rip City Retail')
      expect(find('#search_results')).to_not have_content('Rip City Retail SW')
    end

    it 'machine search blanks out machine_id when you search' do
      rip_location = FactoryBot.create(:location, region: nil, name: 'Rip City Retail SW')
      clark_location = FactoryBot.create(:location, region: nil, name: "Clark's Corner")
      renee_location = FactoryBot.create(:location, region: nil, name: "Renee's Rental")
      FactoryBot.create(:location_machine_xref, location: rip_location, machine: FactoryBot.create(:machine, name: 'Sass'))
      FactoryBot.create(:location_machine_xref, location: clark_location, machine: FactoryBot.create(:machine, name: 'Sass 2'))
      FactoryBot.create(:location_machine_xref, location: renee_location, machine: FactoryBot.create(:machine, name: 'Bawb'))

      visit '/map'

      sleep 1

      fill_in('by_machine_name', with: 'Bawb')
      page.execute_script %{ $('#by_machine_name').trigger('focus') }
      page.execute_script %{ $('#by_machine_name').trigger('keydown') }
      find(:xpath, '//div[text()="Bawb"]').click

      click_on 'location_search_button'

      sleep 1

      expect(find('#search_results')).to have_content('Renee')
      expect(find('#search_results')).to_not have_content('Clark')
      expect(find('#search_results')).to_not have_content('Rip City')

      fill_in('by_location_name', with: "Clark's Corner")

      click_on 'location_search_button'

      sleep 1

      expect(find('#search_results')).to_not have_content('Rip City')
      expect(find('#search_results')).to have_content('Clark')
      expect(find('#search_results')).to_not have_content('Renee')

      expect(page.body).to have_css('#next_link', visible: false)
    end

    it 'shows pagination if greater than 50 locations in results' do
      51.times do |index|
        FactoryBot.create(:location, id: 5678 + index, name: 'Sass Barn ' + index.to_s)
      end

      visit '/map'

      sleep 1

      click_on 'location_search_button'

      sleep 1

      expect(page.body).to have_css('#next_link', visible: true)

      click_link('2')

      sleep 1

      expect(find('#search_results')).to have_content('Sass Barn 9') # because 9 comes after 50

      click_link('1')

      sleep 1

      expect(find('#search_results')).to have_content('Sass Barn 1')
    end

    it 'nearby activity button should return the nearby activity' do
      @location = FactoryBot.create(:location, lat: '45.6008356', lon: '-122.760606', city: 'Portland', zip: '97203', name: "Clark's Depot")
      @distant_location = FactoryBot.create(:location, lat: '12.6008356', lon: '-12.760606', city: 'Hillsboro', zip: '97005', name: "Ripley's Hut")

      FactoryBot.create(:user_submission, created_at: '2025-01-02', location: @location, location_name: @location.name, user_name: 'ssw', machine_name: 'Sassy Madness', submission_type: UserSubmission::NEW_LMX_TYPE)
      FactoryBot.create(:user_submission, created_at: '2025-01-03', location: @distant_location, location_name: @distant_location.name, user_name: 'ssw', machine_name: 'Pizza Attack', submission_type: UserSubmission::REMOVE_MACHINE_TYPE)

      visit '/map'

      fill_in('address', with: '97203')

      click_on 'location_search_button'

      sleep 1

      expect(page).to have_content('Activity feed')

      # Placeholder: map.getCenter() doesn't work in tests because the map doesn't load

      # find('#map_activity_button').click

      # sleep 0.5

      # expect(page).to have_content('1 recent map edits in the nearby area')
      # expect(page).to have_content("added to Clark's Depot")
      # expect(page).to_not have_content("removed from Ripley's Hut")
    end
  end
end
