require 'spec_helper'

describe MapsController do
  before(:each) do
    @region = FactoryBot.create(:region, name: 'portland', full_name: 'Portland')
    @location = FactoryBot.create(:location, region: @region, state: 'OR')
  end

  describe 'map_location_data', type: :request do
    it 'excludes a name-matched location when it does not satisfy an active machine filter' do
      matching_machine = FactoryBot.create(:machine, name: 'Transformers')
      FactoryBot.create(:location_machine_xref, location: @location, machine: matching_machine)
      other_machine = FactoryBot.create(:machine, name: 'Pokemon')

      get map_location_data_path, params: { address: @location.name, by_machine_single_id: [ other_machine.id ] }

      expect(response.body).not_to include(@location.name)
      expect(response.body).to include("locations_geojson = JSON.parse('[]')")
    end

    it 'includes a name-matched location when it satisfies an active machine filter' do
      matching_machine = FactoryBot.create(:machine, name: 'Transformers')
      FactoryBot.create(:location_machine_xref, location: @location, machine: matching_machine)

      get map_location_data_path, params: { address: @location.name, by_machine_single_id: [ matching_machine.id ] }

      expect(response.body).to include(@location.name)
    end
  end

  describe 'get_bounds', type: :request do
    let(:bounds_data) { { sw: { lat: -90, lng: -180 }, ne: { lat: 90, lng: 180 } } }

    before(:each) do
      # a second location within bounds forces the multi-result list branch
      # (a single result renders the location detail partial instead, which has no distance div)
      FactoryBot.create(:location, name: 'Second Location', region: @region, state: 'OR', lat: '12.12', lon: '-12.12')
    end

    it 'shows distance from nearby_lat/nearby_lon when present (Nearby locations search)' do
      post get_bounds_path, params: { boundsData: bounds_data, nearby_lat: '11.11', nearby_lon: '-11.11' }

      expect(response.body).to include('alt="distance"')
    end

    it 'does not show distance when nearby_lat/nearby_lon are absent (plain bounds search)' do
      post get_bounds_path, params: { boundsData: bounds_data }

      expect(response.body).not_to include('alt="distance"')
    end

    it 'filters by by_opdb_id, which has no machine-picker widget of its own and would otherwise be dropped on a pan-and-refresh' do
      matching_machine = FactoryBot.create(:machine, name: 'Transformers', machine_group: nil, opdb_id: 'abc123')
      FactoryBot.create(:location_machine_xref, location: @location, machine: matching_machine)

      post get_bounds_path, params: { boundsData: bounds_data, by_opdb_id: [ 'abc123' ] }

      expect(response.body).to include(@location.name)
      expect(response.body).not_to include('Second Location')
    end

    it 'filters by by_ipdb_id' do
      matching_machine = FactoryBot.create(:machine, name: 'Transformers', machine_group: nil, ipdb_id: 4321)
      FactoryBot.create(:location_machine_xref, location: @location, machine: matching_machine)

      post get_bounds_path, params: { boundsData: bounds_data, by_ipdb_id: [ 4321 ] }

      expect(response.body).to include(@location.name)
      expect(response.body).not_to include('Second Location')
    end

    it 'filters by by_machine_group_id, expanding to every machine in the group' do
      group = FactoryBot.create(:machine_group, name: 'Transformers')
      matching_machine = FactoryBot.create(:machine, name: 'Transformers (Pro)', machine_group: group)
      FactoryBot.create(:location_machine_xref, location: @location, machine: matching_machine)

      post get_bounds_path, params: { boundsData: bounds_data, by_machine_group_id: [ group.id ] }

      expect(response.body).to include(@location.name)
      expect(response.body).not_to include('Second Location')
    end
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
      FactoryBot.create(:machine, name: 'Sass Pro')

      visit '/map'

      # typing in the search field clears hidden location/city fields
      page.execute_script("$('#by_location_id').val('99'); $('#by_city_name').val('Portland'); $('#by_state_name').val('OR');")
      fill_in('address', with: 'foo')
      expect(find('#by_location_id', visible: :hidden).value).to eq('')
      expect(find('#by_city_name', visible: :hidden).value).to eq('')
      expect(find('#by_state_name', visible: :hidden).value).to eq('')

      # typing an address does NOT clear machine selection (near + machine is a valid combo)
      page.find('#open_filter_modal_button').click
      page.find('#by_machine_select + .select2-container .select2-selection').click
      page.find('#by_machine_select + .select2-container .select2-search__field').set('Sass Pro')
      sleep 0.5
      page.find('.select2-results__option', text: /Sass Pro/).click
      page.find('.filter_modal_close').click
      fill_in('address', with: 'foo')
      expect(page.execute_script("return $('#by_machine_select').val()")).to_not eq([])

      # selecting a machine via select2 marks by_location_id and the stale
      # address text for invalidation, but doesn't clear them until Apply
      # is actually submitted - filters shouldn't take effect while the
      # modal is still open
      page.execute_script("$('#by_location_id').val('99'); $('#address').val('Marc\\'s Bar'); $('#by_machine_select').val(null).trigger('change');")
      page.find('#open_filter_modal_button').click
      page.find('#by_machine_select + .select2-container .select2-selection').click
      page.find('#by_machine_select + .select2-container .select2-search__field').set('Sass Pro')
      sleep 0.5
      page.find('.select2-results__option', text: /Sass Pro/).click
      expect(find('#by_location_id', visible: :hidden).value).to eq('99')
      expect(find('#address').value).to eq("Marc's Bar")

      # once Apply is submitted, the stale location fields are cleared so
      # the search doesn't fall back to an unbounded fuzzy name match on
      # whatever venue was previously searched
      page.find('.apply_filters_button').click
      sleep 0.5
      expect(find('#by_location_id', visible: :hidden).value).to eq('')
      expect(find('#address').value).to eq('')
    end

    it 'selecting a specific location from autocomplete clears all active filters' do
      FactoryBot.create(:machine, name: 'Sass Pro')

      visit '/map'

      sleep 1

      # Apply a machine filter
      page.find('#open_filter_modal_button').click
      page.find('#by_machine_select + .select2-container .select2-selection').click
      page.find('#by_machine_select + .select2-container .select2-search__field').set('Sass Pro')
      sleep 0.5
      page.find('.select2-results__option', text: /Sass Pro/).click
      page.find('.filter_modal_close').click
      expect(page.execute_script("return $('#by_machine_select').val()")).to_not be_empty

      # Simulate selecting a specific location from the address autocomplete (not a city)
      page.execute_script("$('#address').autocomplete('instance')._trigger('select', null, { item: { type: 'location', id: 42, name: 'Rip City' } });")

      expect(page.execute_script("return $('#by_machine_select').val()")).to be_empty
      expect(page.find('#clear_filters_button', visible: :all)['style']).to include('display: none')
    end

    it 'lets you search by address and machine and respects if you change or clear out the machine search value' do
      rip_city_location = FactoryBot.create(:location, region: nil, name: 'Rip City', zip: '97203', lat: 45.590502800000, lon: -122.754940100000)
      no_way_location = FactoryBot.create(:location, region: nil, name: 'No Way', zip: '97203', lat: 45.593049200000, lon: -122.732620200000)
      FactoryBot.create(:location, region: nil, name: 'Far Off', city: 'Seattle', state: 'WA', zip: '98121', lat: 47.61307324803172, lon: -122.34479886878611)
      FactoryBot.create(:location_machine_xref, location: rip_city_location, machine: FactoryBot.create(:machine, name: 'Sass Pro'))
      FactoryBot.create(:location_machine_xref, location: no_way_location, machine: FactoryBot.create(:machine, name: 'Bawb Premium'))

      visit '/map'

      fill_in('address', with: '97203')
      page.find('#open_filter_modal_button').click
      page.find('#by_machine_select + .select2-container .select2-selection').click
      page.find('#by_machine_select + .select2-container .select2-search__field').set('Sass Pro')
      sleep 0.5
      page.find('.select2-results__option', text: /Sass Pro/).click
      page.find('.filter_modal_close').click

      click_on 'location_search_button'
      sleep 1

      expect(find('#search_results')).to have_content('Rip City')
      expect(find('#search_results')).to_not have_content('No Way')
      expect(page.body).to have_css('#intro_container', visible: false)

      fill_in('address', with: '97203')
      page.find('#open_filter_modal_button').click
      page.find('.select2-selection__choice__remove').click
      page.find('#by_machine_select + .select2-container .select2-selection').click
      page.find('#by_machine_select + .select2-container .select2-search__field').set('Bawb Premium')
      sleep 0.5
      page.find('.select2-results__option', text: /Bawb Premium/).click
      page.find('.filter_modal_close').click

      click_on 'location_search_button'
      sleep 1

      expect(find('#search_results')).to_not have_content('Rip City')
      expect(find('#search_results')).to have_content('No Way')

      page.find('#open_filter_modal_button').click
      page.find('.clear_filters_button').click
      page.find('.filter_modal_close').click

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
      rip_city_location = FactoryBot.create(:location, region: nil, name: 'Rip City', zip: '97203', lat: 45.590502800000, lon: -122.754940100000)
      no_way_location = FactoryBot.create(:location, region: nil, name: 'No Way', zip: '97203', lat: 45.593049200000, lon: -122.732620200000)
      FactoryBot.create(:location, region: nil, name: 'Far Off', city: 'Seattle', state: 'WA', zip: '98121', lat: 47.61307324803172, lon: -122.34479886878611)
      FactoryBot.create(:location_machine_xref, location: rip_city_location, machine: FactoryBot.create(:machine, name: 'Sass Pro'))
      FactoryBot.create(:location_machine_xref, location: no_way_location, machine: FactoryBot.create(:machine, name: 'Bawb Premium'))

      visit '/map'

      sleep 1

      # simulate selecting Rip City from autocomplete
      page.execute_script("$('#by_location_id').val('#{rip_city_location.id}'); $('#address').val('Rip City'); document.getElementById('clearButton2').style.display = 'block';")

      click_on 'location_search_button'

      sleep 1

      expect(find('#search_results')).to have_content('Rip City')
      expect(find('#search_results')).to_not have_content('No Way')
      expect(find('#search_results')).to_not have_content('Far Off')

      page.find('#clearButton2', visible: false).click

      click_on 'location_search_button'

      sleep 1

      expect(find('#search_results')).to have_content('Rip City')
      expect(find('#search_results')).to have_content('No Way')
      expect(find('#search_results')).to have_content('Far Off')
    end

    it 'lets you filter by location type and number of machines with address and machine name' do
      church_type = FactoryBot.create(:location_type, id: 4, name: 'church')
      lounge_type = FactoryBot.create(:location_type, id: 5, name: 'lounge')
      cleo = FactoryBot.create(:location, id: 38, zip: '97203', lat: 45.590502800000, lon: -122.754940100000, name: 'Cleo', location_type: church_type)
      bawb = FactoryBot.create(:location, id: 39, zip: '97203', lat: 45.593049200000, lon: -122.732620200000, name: 'Bawb')
      sass = FactoryBot.create(:location, id: 40, zip: '97203', lat: 45.593049200000, lon: -122.732620200000, name: 'Sass', location_type: lounge_type)
      jolene = FactoryBot.create(:location, id: 41, zip: '97203', lat: 45.593049200000, lon: -122.732620200000, name: 'Jolene', location_type: lounge_type)
      FactoryBot.create(:location_machine_xref, location: sass, machine: FactoryBot.create(:machine, name: 'Solomon', machine_group: nil))

      5.times do |index|
        FactoryBot.create(:location_machine_xref, machine: FactoryBot.create(:machine, id: 1111 + index, name: 'machine ' + index.to_s), location: cleo)
      end

      25.times do |index|
        FactoryBot.create(:location_machine_xref, machine: FactoryBot.create(:machine, id: 2222 + index, name: 'machine ' + index.to_s), location: sass)
      end

      5.times do |index|
        FactoryBot.create(:location_machine_xref, machine: FactoryBot.create(:machine, id: 3333 + index, name: 'machine ' + index.to_s), location: jolene)
      end

      visit '/map'

      sleep 1

      fill_in('address', with: '97203')

      page.find('#open_filter_modal_button').click
      page.find('#by_type_id + .select2 .selection').click
      select('church', from: 'by_type_id[]')
      page.find('.filter_modal_close').click

      click_on 'location_search_button'

      sleep 1

      expect(page).to have_content('Cleo')
      expect(page).to_not have_content('Bawb')
      expect(page).to_not have_content('Sass')

      visit '/map'

      sleep 1

      fill_in('address', with: '97203')

      page.find('#open_filter_modal_button').click
      page.find('#by_type_id + .select2 .selection').click
      select('lounge', from: 'by_type_id[]')
      page.find('.filter_modal_close').click

      click_on 'location_search_button'

      sleep 1

      expect(page).to_not have_content('Cleo')
      expect(page).to_not have_content('Bawb')
      expect(page).to have_content('Sass')
      expect(page).to have_content('Jolene')

      visit '/map'

      sleep 1

      fill_in('address', with: '97203')

      page.find('#open_filter_modal_button').click
      page.find('#n_machines_10').click
      page.find('.filter_modal_close').click

      click_on 'location_search_button'

      sleep 1

      expect(page).to_not have_content('Cleo')
      expect(page).to_not have_content('Bawb')
      expect(page).to have_content('Sass')

      visit '/map'

      sleep 1

      page.find('#open_filter_modal_button').click
      page.find('#by_machine_select + .select2-container .select2-selection').click
      page.find('#by_machine_select + .select2-container .select2-search__field').set('Solomon')
      sleep 0.5
      page.find('.select2-results__option', text: /Solomon/).click
      page.find('#by_type_id + .select2 .selection').click
      select('lounge', from: 'by_type_id[]')
      page.find('#n_machines_10').click
      page.find('.filter_modal_close').click

      click_on 'location_search_button'

      sleep 1

      expect(page).to_not have_content('Cleo')
      expect(page).to_not have_content('Bawb')
      expect(page).to have_content('Sass')

      visit '/map'

      sleep 1

      page.find('#open_filter_modal_button').click
      page.find('#by_type_id + .select2 .selection').click
      select('lounge', from: 'by_type_id[]')
      page.find('#n_machines_10').click
      page.find('.filter_modal_close').click

      click_on 'location_search_button'

      sleep 1

      expect(page).to_not have_content('Cleo')
      expect(page).to_not have_content('Bawb')
      expect(page).to have_content('Sass')

      visit '/map?by_type_id[]=4'

      sleep 1

      expect(page).to have_content('Cleo')
      expect(page).to_not have_content('Bawb')
      expect(page).to_not have_content('Sass')

      visit '/map?by_at_least_n_machines=5'

      sleep 1

      expect(page).to have_content('Cleo')
      expect(page).to_not have_content('Bawb')
      expect(page).to have_content('Sass')
    end

    it 'shows and hides the clear filters button based on filter state' do
      church_type = FactoryBot.create(:location_type, name: 'church')
      FactoryBot.create(:machine, name: 'Sass Pro')

      visit '/map'
      sleep 1

      expect(page).to have_css('#clear_filters_button', visible: :hidden)

      # visible after selecting a machine
      page.find('#open_filter_modal_button').click
      page.find('#by_machine_select + .select2-container .select2-selection').click
      page.find('#by_machine_select + .select2-container .select2-search__field').set('Sass Pro')
      sleep 0.5
      page.find('.select2-results__option', text: /Sass Pro/).click
      page.find('.filter_modal_close').click

      expect(page).to have_css('#clear_filters_button', visible: true)

      # clicking X clears filters and hides the button
      page.find('#clear_filters_button').click
      sleep 1

      expect(page).to have_css('#clear_filters_button', visible: :hidden)

      # visible after selecting a location type
      page.find('#open_filter_modal_button').click
      page.find('#by_type_id + .select2 .selection').click
      select('church', from: 'by_type_id[]')
      page.find('.filter_modal_close').click

      expect(page).to have_css('#clear_filters_button', visible: true)

      # modal Clear button also hides the X button
      page.find('#open_filter_modal_button').click
      page.find('.clear_filters_button').click

      expect(page).to have_css('#clear_filters_button', visible: :hidden)

      # visible when page loads with filter params in the URL
      visit '/map?by_at_least_n_machines=5'
      sleep 1

      expect(page).to have_css('#clear_filters_button', visible: true)

      # visible when EM machine type filter is active
      visit '/map'
      sleep 1

      page.find('#open_filter_modal_button').click
      page.find('#em_toggle').click
      page.find('.filter_modal_close').click

      expect(page).to have_css('#clear_filters_button', visible: true)

      # modal Clear resets EM filter
      page.find('#open_filter_modal_button').click
      page.find('.clear_filters_button').click

      expect(page).to have_css('#clear_filters_button', visible: :hidden)

      # visible when IC active filter is set (modal is still open after Clear)
      page.find('#ic_toggle').click
      page.find('.filter_modal_close').click

      expect(page).to have_css('#clear_filters_button', visible: true)
    end

    it 'select all link selects all location types and shows clear filters button' do
      FactoryBot.create(:location_type, name: 'bar')
      FactoryBot.create(:location_type, name: 'arcade')

      visit '/map'
      sleep 1

      expect(page).to have_css('#clear_filters_button', visible: :hidden)

      page.find('#open_filter_modal_button').click
      page.find('#select_all_location_types').click

      selected = page.find('#by_type_id', visible: :all).all('option:checked').map(&:text)
      expect(selected).to include('bar', 'arcade')
      page.find('.filter_modal_close').click

      expect(page).to have_css('#clear_filters_button', visible: true)
    end

    it 'shows single version toggle if machine is in a group and respects single version filter' do
      @machine_group = FactoryBot.create(:machine_group)
      rip_city_location = FactoryBot.create(:location, region: nil, name: 'Rip City', zip: '97203', lat: 45.590502800000, lon: -122.754940100000)
      rose_city_location = FactoryBot.create(:location, region: nil, name: 'Rose City', zip: '97203', lat: 45.590502800000, lon: -122.754940100000)
      FactoryBot.create(:location_machine_xref, location: rip_city_location, machine: FactoryBot.create(:machine, name: 'Sass', machine_group: nil))
      FactoryBot.create(:location_machine_xref, location: rip_city_location, machine: FactoryBot.create(:machine, name: 'Dude Pro', machine_group: @machine_group))
      FactoryBot.create(:location_machine_xref, location: rose_city_location, machine: FactoryBot.create(:machine, name: 'Dude Plus', machine_group: @machine_group))

      visit '/map'

      page.find('#open_filter_modal_button').click
      page.find('#by_machine_select + .select2-container .select2-selection').click
      page.find('#by_machine_select + .select2-container .select2-search__field').set('Sass')
      sleep 0.5
      page.find('.select2-results__option', text: /\ASass\z/).click

      sleep 1

      expect(page.body).to have_css('#single_hide', visible: false)

      visit '/map'

      page.find('#open_filter_modal_button').click
      page.find('#by_machine_select + .select2-container .select2-selection').click
      page.find('#by_machine_select + .select2-container .select2-search__field').set('Dude Pro')
      sleep 0.5
      page.find('.select2-results__option', text: /Dude Pro/).click

      expect(page).to have_css('#single_hide', visible: true)

      page.find('.filter_modal_close').click

      click_on 'location_search_button'

      sleep 1

      expect(find('#search_results')).to have_content('Rip')
      expect(find('#search_results')).to have_content('Rose')

      page.find('#open_filter_modal_button').click
      page.find('#selected_version_toggle').click
      page.find('.filter_modal_close').click

      click_on 'location_search_button'

      sleep 1

      expect(find('#search_results')).to have_content('Rip')
      expect(find('#search_results')).to_not have_content('Rose')
    end

    it 'shows IC version toggle for ic_eligible machine and respects IC filter' do
      ic_machine = FactoryBot.create(:machine, name: 'IC Wizard', ic_eligible: true, machine_group: nil)
      ic_location = FactoryBot.create(:location, region: nil, name: 'IC Rip City', zip: '97203', lat: 45.590502800000, lon: -122.754940100000)
      no_ic_location = FactoryBot.create(:location, region: nil, name: 'No IC City', zip: '97203', lat: 45.593049200000, lon: -122.732620200000)
      FactoryBot.create(:location_machine_xref, location: ic_location, machine: ic_machine, ic_enabled: true)
      FactoryBot.create(:location_machine_xref, location: no_ic_location, machine: ic_machine, ic_enabled: false)

      visit '/map'

      page.find('#open_filter_modal_button').click
      page.find('#by_machine_select + .select2-container .select2-selection').click
      page.find('#by_machine_select + .select2-container .select2-search__field').set('IC Wizard')
      sleep 0.5
      page.find('.select2-results__option', text: /IC Wizard/).click

      expect(page).to have_css('#ic_eligible_hide', visible: true)

      page.find('.filter_modal_close').click
      click_on 'location_search_button'
      sleep 1

      expect(find('#search_results')).to have_content('IC Rip City')
      expect(find('#search_results')).to have_content('No IC City')

      page.find('#open_filter_modal_button').click
      page.find('#has_ic_version_toggle').click
      page.find('.filter_modal_close').click

      click_on 'location_search_button'
      sleep 1

      expect(find('#search_results')).to have_content('IC Rip City')
      expect(find('#search_results')).to_not have_content('No IC City')
    end

    it 'filters by EM machine type' do
      em_location = FactoryBot.create(:location, region: nil, name: 'EM Hall', zip: '97203', lat: 45.590502800000, lon: -122.754940100000)
      ss_location = FactoryBot.create(:location, region: nil, name: 'SS Hall', zip: '97203', lat: 45.593049200000, lon: -122.732620200000)
      FactoryBot.create(:location_machine_xref, location: em_location, machine: FactoryBot.create(:machine, name: 'Electro Wizard', machine_type: 'em', machine_group: nil))
      FactoryBot.create(:location_machine_xref, location: ss_location, machine: FactoryBot.create(:machine, name: 'Solid State Game', machine_type: 'ss', machine_group: nil))

      visit '/map'
      sleep 1

      page.find('#open_filter_modal_button').click
      page.find('#em_toggle').click
      page.find('.apply_filters_button').click

      sleep 1

      expect(page).to have_content('EM Hall')
      expect(page).to_not have_content('SS Hall')
    end

    it 'filters by IC active location' do
      ic_location = FactoryBot.create(:location, region: nil, name: 'IC Venue', zip: '97203', ic_active: true, lat: 45.590502800000, lon: -122.754940100000)
      no_ic_location = FactoryBot.create(:location, region: nil, name: 'Non IC Venue', zip: '97203', ic_active: false, lat: 45.593049200000, lon: -122.732620200000)
      FactoryBot.create(:location_machine_xref, location: ic_location, machine: FactoryBot.create(:machine, name: 'IC Active Machine', machine_group: nil))
      FactoryBot.create(:location_machine_xref, location: no_ic_location, machine: FactoryBot.create(:machine, name: 'Regular Machine', machine_group: nil))

      visit '/map'
      sleep 1

      page.find('#open_filter_modal_button').click
      page.find('#ic_toggle').click
      page.find('.apply_filters_button').click

      sleep 1

      expect(page).to have_content('IC Venue')
      expect(page).to_not have_content('Non IC Venue')
    end

    it 'filters by operator' do
      operator = FactoryBot.create(:operator, name: 'Fun Operators')
      op_location = FactoryBot.create(:location, region: nil, name: 'Operator Venue', zip: '97203', operator: operator, lat: 45.590502800000, lon: -122.754940100000)
      other_location = FactoryBot.create(:location, region: nil, name: 'Other Venue', zip: '97203', lat: 45.593049200000, lon: -122.732620200000)
      FactoryBot.create(:location_machine_xref, location: op_location, machine: FactoryBot.create(:machine, name: 'Op Machine', machine_group: nil))
      FactoryBot.create(:location_machine_xref, location: other_location, machine: FactoryBot.create(:machine, name: 'Other Machine', machine_group: nil))

      visit '/map'
      sleep 1

      page.find('#open_filter_modal_button').click
      page.find('#by_operator_id + .select2 .selection').click
      page.find('.select2-search--dropdown .select2-search__field').set('Fun')
      sleep 0.5
      page.find('.select2-results__option', text: /Fun Operators/).click
      page.find('.apply_filters_button').click

      sleep 1

      expect(page).to have_content('Operator Venue')
      expect(page).to_not have_content('Other Venue')
    end

    it 'filters by machine year range' do
      early_location = FactoryBot.create(:location, region: nil, name: 'Early Bird', zip: '97203', lat: 45.590502800000, lon: -122.754940100000)
      late_location = FactoryBot.create(:location, region: nil, name: 'Late Bloomer', zip: '97203', lat: 45.593049200000, lon: -122.732620200000)
      FactoryBot.create(:location_machine_xref, location: early_location, machine: FactoryBot.create(:machine, name: 'Vintage Game', year: 1975, machine_group: nil))
      FactoryBot.create(:location_machine_xref, location: late_location, machine: FactoryBot.create(:machine, name: 'Modern Game', year: 2020, machine_group: nil))

      visit '/map'
      sleep 1

      page.find('#open_filter_modal_button').click
      select '2020', from: 'by_machine_year_gte'
      page.find('.apply_filters_button').click

      sleep 1

      expect(page).to have_content('Late Bloomer')
      expect(page).to_not have_content('Early Bird')

      visit '/map'
      sleep 1

      page.find('#open_filter_modal_button').click
      select '1975', from: 'by_machine_year_lte'
      page.find('.apply_filters_button').click

      sleep 1

      expect(page).to have_content('Early Bird')
      expect(page).to_not have_content('Late Bloomer')
    end

    it 'respects user_faved filter' do
      user = FactoryBot.create(:user)
      login(user)

      FactoryBot.create(:user_fave_location, user: user, location: FactoryBot.create(:location, name: 'Foo'))
      FactoryBot.create(:user_fave_location, user: user, location: FactoryBot.create(:location, name: 'Bar'))
      FactoryBot.create(:user_fave_location, location: FactoryBot.create(:location, name: 'Baz'))

      visit "/map?user_faved=#{user.id}"
      sleep 1

      expect(page.body).to have_content('Foo')
      expect(page.body).to have_content('Bar')
      expect(page.body).to_not have_content('Baz')
    end

    it 'hides the saved filter toggle from logged-out users' do
      visit '/map'
      sleep 1

      page.find('#open_filter_modal_button').click

      expect(page).to_not have_css('#my_saved_toggle')
    end

    it 'filters to saved locations via My Saved toggle' do
      user = FactoryBot.create(:user)
      login(user)

      faved_location = FactoryBot.create(:location, name: 'Pinball Palace', zip: '97203', lat: 45.590502800000, lon: -122.754940100000)
      other_location = FactoryBot.create(:location, name: 'Other Arcade', zip: '97203', lat: 45.593049200000, lon: -122.732620200000)
      FactoryBot.create(:location_machine_xref, location: faved_location, machine: FactoryBot.create(:machine, name: 'Faved Game', machine_group: nil))
      FactoryBot.create(:location_machine_xref, location: other_location, machine: FactoryBot.create(:machine, name: 'Other Game', machine_group: nil))
      FactoryBot.create(:user_fave_location, user: user, location: faved_location)

      visit '/map'
      sleep 1

      fill_in('address', with: '97203')
      page.find('#open_filter_modal_button').click
      page.find('#my_saved_toggle').click
      page.find('.apply_filters_button').click
      sleep 1

      expect(page).to have_content('Pinball Palace')
      expect(page).to_not have_content('Other Arcade')
    end

    it 'shows clear filters button when My Saved is active and resets it on clear' do
      user = FactoryBot.create(:user)
      login(user)

      visit '/map'
      sleep 1

      page.find('#open_filter_modal_button').click
      page.find('#my_saved_toggle').click
      page.find('.filter_modal_close').click

      expect(page).to have_css('#clear_filters_button', visible: true)

      page.find('#open_filter_modal_button').click
      page.find('.clear_filters_button').click

      expect(page).to have_css('#clear_filters_button', visible: :hidden)
      expect(page).to have_css('#all_saved_toggle.active')
      expect(page).to_not have_css('#my_saved_toggle.active')
    end

    it 'restores My Saved toggle from user_faved URL param' do
      user = FactoryBot.create(:user)
      login(user)

      faved_location = FactoryBot.create(:location, name: 'Saved Spot', zip: '97203', lat: 45.590502800000, lon: -122.754940100000)
      FactoryBot.create(:location, name: 'Other Spot', zip: '97203', lat: 45.593049200000, lon: -122.732620200000)
      FactoryBot.create(:location_machine_xref, location: faved_location, machine: FactoryBot.create(:machine, name: 'Deep Link Game', machine_group: nil))
      FactoryBot.create(:user_fave_location, user: user, location: faved_location)

      visit '/map?user_faved=1'
      sleep 1

      expect(page).to have_css('#my_saved_toggle.active', visible: false)
      expect(page).to have_css('#clear_filters_button', visible: true)
      expect(page).to have_content('Saved Spot')
      expect(page).to_not have_content('Other Spot')
    end

    it 'filters by opdb_id URL param on initial load and keeps the filter after the map bounds reload' do
      machine = FactoryBot.create(:machine, name: 'Deep Link Game', opdb_id: 'GweeP-MW95j', machine_group: nil)
      matching_location = FactoryBot.create(:location, name: 'OPDB Spot', zip: '97203', lat: 45.590502800000, lon: -122.754940100000)
      FactoryBot.create(:location, name: 'Other Spot', zip: '97203', lat: 45.593049200000, lon: -122.732620200000)
      FactoryBot.create(:location_machine_xref, location: matching_location, machine: machine)

      visit "/map?by_opdb_id=#{machine.opdb_id}"
      sleep 1

      expect(page).to have_content('OPDB Spot')
      expect(page).to_not have_content('Other Spot')
    end

    it 'lets you search by address -- displays "Not Found" if no results' do
      FactoryBot.create(:location, region: nil, name: 'Troy', zip: '48098', lat: 42.5925, lon: 83.1756)

      visit '/map'

      sleep 1

      fill_in('address', with: '97203')

      click_on 'location_search_button'

      sleep 1

      expect(page).to have_content("No results in the current map view.\nZoom out - move the map - change your filters - try again.")
    end

    it 'location autocomplete select ensures you only search by a single location' do
      FactoryBot.create(:location, region: nil, name: 'Rip City Retail SW')
      FactoryBot.create(:location, region: nil, name: 'Rip City Retail', city: 'Portland', state: 'OR')

      visit '/map'

      sleep 1

      fill_in('address', with: 'Rip')
      page.execute_script %{ $('#address').trigger('focus') }
      page.execute_script %{ $('#address').trigger('keydown') }
      find(:xpath, '//div[text()="Rip City Retail (Portland, OR)"]').click

      sleep 1

      expect(find('#search_results')).to have_content('Rip City Retail')
      expect(find('#search_results')).to_not have_content('Rip City Retail SW')
    end

    it 'machine search blanks out machine selection when you search by location name' do
      rip_location = FactoryBot.create(:location, region: nil, name: 'Rip City Retail SW', lat: '45.5905', lon: '-122.7549')
      clark_location = FactoryBot.create(:location, region: nil, name: "Clark's Corner", lat: '45.5905', lon: '-122.7549')
      rebo_location = FactoryBot.create(:location, region: nil, name: "Rebo's Rental", lat: '45.5905', lon: '-122.7549')
      FactoryBot.create(:location_machine_xref, location: rip_location, machine: FactoryBot.create(:machine, name: 'Sass'))
      FactoryBot.create(:location_machine_xref, location: clark_location, machine: FactoryBot.create(:machine, name: 'Sass 2'))
      FactoryBot.create(:location_machine_xref, location: rebo_location, machine: FactoryBot.create(:machine, name: 'Bawb'))

      visit '/map'

      sleep 1

      page.find('#open_filter_modal_button').click
      page.find('#by_machine_select + .select2-container .select2-selection').click
      page.find('#by_machine_select + .select2-container .select2-search__field').set('Bawb')
      sleep 0.5
      page.find('.select2-results__option', text: /\ABawb\z/).click
      page.find('.filter_modal_close').click

      click_on 'location_search_button'

      sleep 1

      expect(find('#search_results')).to have_content('Rebo')
      expect(find('#search_results')).to_not have_content('Clark')
      expect(find('#search_results')).to_not have_content('Rip City')

      # simulate selecting Clark's Corner from autocomplete
      page.execute_script("$('#by_location_id').val('#{clark_location.id}'); $('#by_machine_select').val(null).trigger('change');")

      click_on 'location_search_button'

      sleep 1

      expect(find('#search_results')).to_not have_content('Rip City')
      expect(find('#search_results')).to have_content('Clark')
      expect(find('#search_results')).to_not have_content('Rebo')

      expect(page.body).to have_css('#next_link', visible: false)
    end

    it 'shows pagination if greater than 50 locations in results' do
      51.times do |index|
        FactoryBot.create(:location, id: 5678 + index, lat: '45.5905', lon: '-122.7549', name: 'Sass Barn ' + index.to_s)
      end

      visit '/map'

      sleep 1

      expect(page.body).to have_css('#next_link', visible: true)

      click_link('2')

      sleep 1

      expect(find('#search_results')).to have_content('Sass Barn 9') # because 9 comes after 50

      click_link('1')

      sleep 1

      expect(find('#search_results')).to have_content('Sass Barn 1')
    end

    it 'fuzzy matches a location name when no autocomplete suggestion is selected, and falls through to geocode when no match' do
      FactoryBot.create(:location, region: nil, name: 'Revenge Of The Yeti', city: 'Portland', state: 'OR', lat: '45.5905', lon: '-122.7549')
      FactoryBot.create(:location, region: nil, name: 'Unrelated Spot', city: 'Portland', state: 'OR', lat: '45.5905', lon: '-122.7549')

      visit '/map'
      sleep 1

      fill_in('address', with: 'Revenge Of')
      click_on 'location_search_button'
      sleep 1

      expect(find('#search_results')).to have_content('Revenge Of The Yeti')
      expect(find('#search_results')).to_not have_content('Unrelated Spot')

      # A string that matches no location name falls through to geocode;
      # in test env geocode is skipped and nearby_locations returns nothing.
      fill_in('address', with: 'zzz_no_match_xyz')
      click_on 'location_search_button'
      sleep 1

      expect(page).to have_content('No results in the current map view.')
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
    end
  end
end
