require 'spec_helper'

describe LocationsController do
  before(:each) do
    @region = FactoryBot.create(:region, name: 'portland', full_name: 'portland', lat: 1, lon: 2, motd: 'This is a MOTD', n_search_no: 4, should_email_machine_removal: 0)
  end

  describe 'add as fave', type: :feature, js: true do
    it "doesn't give you the option unless you're logged in" do
      location = FactoryBot.create(:location, region: @region, name: 'Cleo')

      visit "/#{@region.name}/?by_location_id=" + location.id.to_s

      expect(page).to_not have_selector("#fave_location_#{location.id}")
    end

    it 'toggles between faved and unfaved when clicked' do
      user = FactoryBot.create(:user)
      login(user)

      location = FactoryBot.create(:location, region: @region, name: 'Cleo')

      visit "/#{@region.name}/?by_location_id=" + location.id.to_s

      expect(page).to have_selector("#fave_location_img_#{location.id}")

      expect(UserFaveLocation.where(location: location, user: user).size).to eq(0)
      expect(page.find("#fave_location_img_#{location.id}")['src']).to have_content('heart-empty')

      find("#fave_location_img_#{location.id}").click

      sleep 1

      expect(UserFaveLocation.where(location: location, user: user).size).to eq(1)
      expect(page.find("#fave_location_img_#{location.id}")['src']).to have_content('heart-filled')

      find("#fave_location_img_#{location.id}").click

      sleep 1

      expect(UserFaveLocation.where(location: location, user: user).size).to eq(0)
      expect(page.find("#fave_location_img_#{location.id}")['src']).to have_content('heart-empty')
    end
  end

  describe 'confirm location', type: :feature, js: true do
    before(:each) do
      @user = FactoryBot.create(:user, username: 'ssw')
      login(@user)
    end

    [ Region.find_by_name('portland'), nil ].each do |region|
      it 'lets you click a button to update the date_last_updated' do
        location = FactoryBot.create(:location, region: region, name: 'Cleo')

        visit "/#{region ? region.name : 'map'}/?by_location_id=" + location.id.to_s

        sleep 1
        page.accept_alert 'Thanks for confirming this line-up!' do
          find("#confirm_location_button_#{location.id}.confirm_button").click
        end

        sleep 1

        expect(location.reload.date_last_updated).to eq(Date.today)
        expect(find("#last_updated_location_#{location.id}")).to have_content("Last updated: #{Time.now.strftime('%b %d, %Y')} by ssw")
        expect(URI.parse(page.find_link('ssw')['href']).to_s).to match(%r{/users/#{@user.username}/profile})
        expect(UserSubmission.count).to eq(1)

        sleep 1
        page.accept_alert 'Thanks for confirming this line-up!' do
          find("#confirm_location_button_#{location.id}.confirm_button").click
        end

        expect(UserSubmission.count).to eq(1)

        FactoryBot.create(:user_submission, created_at: Time.now, location: location, machine_name: 'Pizza Attack', submission_type: UserSubmission::NEW_LMX_TYPE)

        page.accept_alert 'Thanks for confirming this line-up!' do
          find("#confirm_location_button_#{location.id}.confirm_button").click
        end

        expect(UserSubmission.count).to eq(3)
      end
    end

    it 'displays no username when it was last updated by a non-user' do
      location = FactoryBot.create(:location, region_id: @region.id, name: 'Cleo')

      location.date_last_updated = Date.today
      location.save(validate: false)

      visit '/portland/?by_location_id=' + location.id.to_s

      expect(find("#last_updated_location_#{location.id}")).to have_content("Last updated: #{Time.now.strftime('%b %d, %Y')}")
    end

    it 'displays number of edits and distinct users who edited' do
      location = FactoryBot.create(:location, region_id: @region.id, name: 'Cleo')
      FactoryBot.create(:user_submission, created_at: Time.now, location: location, machine_name: 'Pizza Attack', user_id: 54, submission_type: UserSubmission::NEW_LMX_TYPE)
      location.update_column(:users_count, 1)
      FactoryBot.create(:user_submission, created_at: Time.now, location: location, machine_name: 'Pizza Attack', user_id: 55, submission_type: UserSubmission::REMOVE_MACHINE_TYPE)
      location.update_column(:users_count, 2)

      location.date_last_updated = Date.today
      location.save(validate: false)

      visit '/portland/?by_location_id=' + location.id.to_s

      expect(find("#last_updated_location_#{location.id}")).to have_content("Location updated 3 times by 2 users")
    end
  end

  describe 'stale location notice', type: :feature, js: true do
    before(:each) do
    end

    it 'shows stale data notice if location has not been updated in over two years' do
      location = FactoryBot.create(:location, region_id: @region.id, name: 'Cleo')

      location.date_last_updated = 3.years.ago
      location.save(validate: false)

      visit '/portland/?by_location_id=' + location.id.to_s

      expect(find("#stale_#{location.id}")).to have_content('This location has not been updated in')
    end

    it 'hides stale data notice if location has been updated in past two years' do
      location = FactoryBot.create(:location, region_id: @region.id, name: 'Cleo')

      location.date_last_updated = Date.today
      location.save(validate: false)

      visit '/portland/?by_location_id=' + location.id.to_s

      expect(page).to_not have_selector("#stale_#{location.id}")
    end
  end

  describe 'remove machine - not authed', type: :feature, js: true do
    before(:each) do
      @location = FactoryBot.create(:location, region_id: @region.id, name: 'Cleo')
      @machine = FactoryBot.create(:machine, name: 'Bawb')
    end

    it 'removes a machine from a location' do
      FactoryBot.create(:location_machine_xref, location: @location, machine: @machine)

      @location.reload

      sleep 1

      visit '/portland/?by_location_id=' + @location.id.to_s

      sleep 1

      expect(page).to_not have_selector("input#remove_machine_#{LocationMachineXref.where(location_id: @location.id, machine_id: @machine.id).first.id}")
    end
  end

  describe 'remove machine', type: :feature, js: true do
    before(:each) do
      @user = FactoryBot.create(:user, id: 1001, username: 'ssw', email: 'ssw@test.com')
      login(@user)

      @location = FactoryBot.create(:location, region_id: @region.id, name: 'Cleo')
      @machine = FactoryBot.create(:machine, name: 'Bawb')
    end

    [ true, false ].each do |region|
      it 'removes a machine from a location' do
        region = region ? @region : nil
        location = FactoryBot.create(:location, name: 'Cleo', city: 'Portland', region: region)

        FactoryBot.create(:location_machine_xref, location: location, machine: @machine)

        visit "/#{region ? region.name : 'map'}/?by_location_id=" + location.id.to_s

        page.accept_confirm do
          click_button 'Remove'
        end

        sleep 1

        expect(LocationMachineXref.all).to eq([])
        expect(location.reload.date_last_updated).to eq(Date.today)
        expect(find("#last_updated_location_#{location.id}")).to have_content("Last updated: #{Time.now.strftime('%b %d, %Y')}")

        expect(UserSubmission.count).to eq(2)
        submission = UserSubmission.second
        expect(submission.submission_type).to eq(UserSubmission::REMOVE_MACHINE_TYPE)

        expect(submission.submission).to eq("Bawb was removed from Cleo in Portland by #{@user.username}")
        expect(submission.user_id).to eq(User.last.id)
        expect(submission.region).to eq(location.region)
      end
    end

    it 'removes a machine from a location - allows you to cancel out of remove' do
      lmx = FactoryBot.create(:location_machine_xref, location: @location, machine: @machine)

      visit '/portland/?by_location_id=' + @location.id.to_s

      page.dismiss_confirm do
        click_button 'Remove'
      end

      sleep 1

      expect(LocationMachineXref.all).to eq([ lmx ])
    end
  end

  describe 'search locations', type: :feature, js: true do
    before(:each) do
    end

    [ true, false ].each do |region|
      it 'sets title and description appropriately if one location is returned' do
        region = region ? @region : nil
        FactoryBot.create(:location, region: region, name: 'Cleo')

        location = FactoryBot.create(:location, region: region, name: 'Zelda', street: '1234 Foo St.', city: 'Portland', zip: '97203', id: 212)
        machine = FactoryBot.create(:machine, name: 'Bawb')
        FactoryBot.create(:location_machine_xref, location: location, machine: machine)

        old_style_title = "#{region ? region.name + ' ' : ''}Pinball Map"
        single_location_title = "Zelda - #{region ? region.name + ' ' : ''}Pinball Map"
        old_style_description = "Find local places to play pinball! The #{region ? region.name + ' ' : ''}Pinball Map is a high-quality user-updated pinball locator for all the public pinball machines in your area."

        visit "/#{region ? region.name : 'map'}"

        sleep 1

        desc_tag = "meta[name=\"description\"][content=\"#{old_style_description}\"]"
        og_desc_tag = "meta[property=\"og:description\"][content=\"#{old_style_description}\"]"
        og_title_tag = "meta[property=\"og:title\"][content=\"#{old_style_title}\"]"

        expect(page.title).to eq("#{region ? region.name + ' ' : ''}Pinball Map")
        expect(page.body).to have_css(desc_tag, visible: :hidden)
        expect(page.body).to have_css(og_title_tag, visible: :hidden)
        expect(page.body).to have_css(og_desc_tag, visible: :hidden)

        fill_in('by_location_name', with: 'Zelda')
        click_on 'location_search_button'

        sleep 1

        desc_tag = "meta[name=\"description\"][content=\"#{old_style_description}\"]"
        og_desc_tag = "meta[property=\"og:description\"][content=\"#{old_style_description}\"]"
        og_title_tag = "meta[property=\"og:title\"][content=\"#{single_location_title}\"]"
        expect(page).to have_title(single_location_title)
        expect(page.body).to have_css(desc_tag, visible: :hidden)
        expect(page.body).to have_css(og_desc_tag, visible: :hidden)
        expect(page.body).to have_css(og_title_tag, visible: :hidden) if region

        visit "/#{region ? region.name + '?by_location_id=212' : 'map?by_location_id=212'}"

        sleep 1

        expect(page.title).to eq(single_location_title)
        page.find 'meta[name="description"]', visible: false
        expect(page).to have_title(old_style_title) if region

        fill_in('by_location_name', with: '')
        click_on 'location_search_button'

        sleep 1

        expect(page.title).to eq("#{region ? region.name + ' ' : ''}Pinball Map")
        page.find 'meta[name="description"]', visible: false
        expect(page).to have_title(old_style_title)
      end
    end

    it 'displays the number of locations returned in a search' do
      FactoryBot.create(:location, region: @region, name: 'Cleo')
      FactoryBot.create(:location, region: @region, name: 'Zelda')

      visit '/portland'

      click_on 'location_search_button'

      within('div#search_results_count') do
        expect(page).to have_content('2 locations')
      end
    end

    it 'displays a max of 5 machines per location when multiple locations in results' do
      cleo = FactoryBot.create(:location, id: 51, region: @region, name: 'Cleo')
      zelda = FactoryBot.create(:location, id: 61, region: @region, name: 'Zelda')

      5.times do |index|
        FactoryBot.create(:location_machine_xref, machine: FactoryBot.create(:machine, id: 1111 + index, name: 'machine ' + index.to_s), location: cleo)
      end

      25.times do |index|
        FactoryBot.create(:location_machine_xref, machine: FactoryBot.create(:machine, id: 2222 + index, name: 'machine ' + index.to_s), location: zelda)
      end

      visit '/portland'

      click_on 'location_search_button'

      within('div#show_location_detail_location_61') do
        expect(page).to have_content('plus 20 more machines')
      end
    end

    it 'shows numbers of machines at location' do
      cleo = FactoryBot.create(:location, id: 53, region: @region, name: 'Cleo')

      5.times do |index|
        FactoryBot.create(:location_machine_xref, machine: FactoryBot.create(:machine, id: 1311 + index, name: 'machine ' + index.to_s), location: cleo)
      end

      visit '/portland'

      fill_in('by_location_name', with: 'Cleo')
      select('Cleo', from: 'by_location_id')

      click_on 'location_search_button'

      within('div.lmx_count') do
        expect(page).to have_content('5 machines')
      end
    end

    it 'handles missing zip or state fields' do
      FactoryBot.create(:location, id: 63, name: 'Cleo', street: '123 Meow St', zip: '90210')
      FactoryBot.create(:location, id: 64, name: 'Cleo', street: '123 Meow St', state: 'OR')
      FactoryBot.create(:location, id: 65, name: 'Cleo', street: '123 Meow St')

      visit '/map?by_location_id=63'

      expect(page).to have_content('Cleo')

      visit '/map?by_location_id=64'

      expect(page).to have_content('Cleo')

      visit '/map?by_location_id=65'

      expect(page).to have_content('Cleo')
    end

    it 'favors by_location_name when search by both by_location_id and by_location_name' do
      FactoryBot.create(:location, region: @region, name: 'Cleo')
      FactoryBot.create(:location, region: @region, name: 'Zelda')

      visit '/portland'

      fill_in('by_location_name', with: 'Zelda')
      select('Cleo', from: 'by_location_id')

      click_on 'location_search_button'

      within('div#search_results') do
        expect(page).to have_content('Zelda')
      end
    end

    it 'does not display region name in a region map search' do
      pdx_location = FactoryBot.create(:location, region: @region, name: 'Cleo')

      visit '/portland'

      click_on 'location_search_button'

      within('div#search_results') do
        expect(page).to have_content('Cleo')
        expect(page).to_not have_content('Region: portland')
      end

      visit '/portland/?by_location_id=' + pdx_location.id.to_s

      within('div#search_results') do
        expect(page).to have_content('Cleo')
        expect(page).to_not have_content('Region: portland')
      end
    end

    it 'displays a location not found message instead of the ocean' do
      visit '/portland/?by_location_id=-1'

      expect(page).to have_content("NOT FOUND. PLEASE SEARCH AGAIN.\nUse the dropdown or the autocompleting textbox if you want results.")
    end
  end

  describe 'initial search by passed in param', type: :feature, js: true do
    before(:each) do
      @type = FactoryBot.create(:location_type, name: 'Bar')
      @zone = FactoryBot.create(:zone, region: @region, name: 'DT')
      @operator = FactoryBot.create(:operator, region: @region, name: 'Quarterworld')
      @location = FactoryBot.create(:location, region: @region, city: 'Portland', name: 'Cleo', zone: @zone, location_type: @type, operator: @operator)
      @machine = FactoryBot.create(:machine, name: 'Barb', ipdb_id: 777, opdb_id: 'b33f')
      FactoryBot.create(:location_machine_xref, location: @location, machine: @machine)

      FactoryBot.create(:location, region: @region, name: 'Sass', city: 'Beaverton')
    end

    it 'by_city_id' do
      visit '/portland/?by_city_id=' + @location.city

      expect(find('#search_results')).to have_content('Cleo')
      expect(find('#search_results')).to_not have_content('Sass')
    end

    it 'by_operator_id' do
      visit '/portland/?by_operator_id=' + @location.operator_id.to_s

      sleep 1

      expect(find('#search_results')).to have_content('Cleo')
      expect(find('#search_results')).to_not have_content('Sass')
    end

    it 'by_machine_group_id' do
      machine_group = FactoryBot.create(:machine_group, id: 1001, name: 'Sass')
      sass_reg_ed = FactoryBot.create(:machine, name: 'Sass Reg Ed', machine_group_id: 1001)
      sass_tourn_ed = FactoryBot.create(:machine, name: 'Sass Tournament Ed', machine_group_id: 1001)
      machine_group_location = FactoryBot.create(:location, region: @region)

      FactoryBot.create(:location_machine_xref, location: machine_group_location, machine: sass_reg_ed)
      FactoryBot.create(:location_machine_xref, location: machine_group_location, machine: sass_tourn_ed)

      visit '/portland/?by_machine_group_id=' + machine_group.id.to_s

      expect(find('#search_results')).to have_content('Sass Reg Ed')
      expect(find('#search_results')).to have_content('Sass Tournament Ed')
      expect(find('#search_results')).to_not have_content('Barb')
    end

    it 'by_machine_single_id' do
      sass_reg_ed = FactoryBot.create(:machine, name: 'Sass Reg Ed', machine_group_id: 1001)
      sass_tourn_ed = FactoryBot.create(:machine, name: 'Sass Tournament Ed', machine_group_id: 1001)
      machine_group_location = FactoryBot.create(:location, region: @region)
      machine_group_location2 = FactoryBot.create(:location, region: @region)

      FactoryBot.create(:location_machine_xref, location: machine_group_location, machine: sass_reg_ed)
      FactoryBot.create(:location_machine_xref, location: machine_group_location2, machine: sass_tourn_ed)

      visit '/portland/?by_machine_single_id=' + sass_reg_ed.id.to_s

      expect(find('#search_results')).to have_content('Sass Reg Ed')
      expect(find('#search_results')).to_not have_content('Sass Tournament Ed')
      expect(find('#search_results')).to_not have_content('Barb')
    end

    it 'by_location_id' do
      visit '/portland/?by_location_id=' + @location.id.to_s

      expect(find('#search_results')).to have_content('Cleo')
      expect(find('#search_results')).to_not have_content('Sass')
    end

    it 'by_location_id -- multiple ids' do
      other_location = FactoryBot.create(:location, region: @region, name: 'Zelda')

      visit '/portland/?by_location_id=' + @location.id.to_s + '_' + other_location.id.to_s

      expect(find('#search_results')).to have_content('Cleo')
      expect(find('#search_results')).to have_content('Zelda')
      expect(find('#search_results')).to_not have_content('Sass')
    end

    it 'by_zone_id' do
      visit '/portland/?by_zone_id=' + @zone.id.to_s

      expect(find('#search_results')).to have_content('Cleo')
      expect(find('#search_results')).to_not have_content('Sass')
    end

    it 'by_zone_id -- multiple ids' do
      other_zone = FactoryBot.create(:zone, name: 'NE')
      FactoryBot.create(:location, region: @region, name: 'Zelda', zone: other_zone)
      visit '/portland/?by_zone_id=' + @zone.id.to_s + '_' + other_zone.id.to_s

      expect(find('#search_results')).to have_content('Cleo')
      expect(find('#search_results')).to have_content('Zelda')
      expect(find('#search_results')).to_not have_content('Sass')
    end

    it 'by_type_id' do
      visit '/portland/?by_type_id=' + @type.id.to_s

      expect(find('#search_results')).to have_content('Cleo')
      expect(find('#search_results')).to_not have_content('Sass')
    end

    it 'by_type_id -- multiple ids' do
      other_type = FactoryBot.create(:location_type, name: 'PUB')
      FactoryBot.create(:location, region: @region, name: 'Zelda', location_type: other_type)

      visit '/portland/?by_type_id=' + @type.id.to_s + '_' + other_type.id.to_s

      expect(find('#search_results')).to have_content('Cleo')
      expect(find('#search_results')).to have_content('Zelda')
      expect(find('#search_results')).to_not have_content('Sass')
    end

    it 'by_ipdb_id' do
      visit '/portland/?by_ipdb_id=' + @machine.ipdb_id.to_s

      expect(find('#search_results')).to have_content('Cleo')
      expect(find('#search_results')).to_not have_content('Sass')
    end

    it 'by_opdb_id' do
      visit '/portland/?by_opdb_id=' + @machine.opdb_id.to_s

      expect(find('#search_results')).to have_content('Cleo')
      expect(find('#search_results')).to_not have_content('Sass')
    end

    it 'by_machine_id' do
      visit '/portland/?by_machine_id=' + @machine.id.to_s

      expect(find('#search_results')).to have_content('Cleo')
      expect(find('#search_results')).to_not have_content('Sass')
    end

    it 'by_machine_id -- multiple ids' do
      other_machine = FactoryBot.create(:machine, name: 'Cool')
      other_location = FactoryBot.create(:location, region: @region, name: 'Zelda')
      FactoryBot.create(:location_machine_xref, location: other_location, machine: other_machine)

      visit '/portland/?by_machine_id=' + @machine.id.to_s + '_' + other_machine.id.to_s

      expect(find('#search_results')).to have_content('Cleo')
      expect(find('#search_results')).to have_content('Zelda')
      expect(find('#search_results')).to_not have_content('Sass')
    end

    it 'by_city_name alone includes all locations with that city value regardless of state' do
      location = FactoryBot.create(:location, city: 'McGannyville', state: 'CA', name: 'Cleo')
      FactoryBot.create(:location, city: 'McGannyville', state: '', name: 'Sass')
      FactoryBot.create(:location, city: 'McGannyville', state: 'TX', name: 'Jolene')
      FactoryBot.create(:location, city: 'Weakerton', state: 'OR', name: 'Plover')

      visit '/map/?by_city_name=' + location.city.to_s

      expect(find('#search_results')).to have_content('Cleo')
      expect(find('#search_results')).to have_content('Sass')
      expect(find('#search_results')).to have_content('Jolene')
      expect(find('#search_results')).to_not have_content('Plover')
    end

    it 'by_city_name with by_state_name does not include locations that match city but not state' do
      location = FactoryBot.create(:location, city: 'McGannyville', state: 'CA', name: 'Cleo')
      FactoryBot.create(:location, city: 'McGannyville', state: '', name: 'Sass')
      FactoryBot.create(:location, city: 'McGannyville', state: 'TX', name: 'Jolene')
      FactoryBot.create(:location, city: 'Weakerton', state: 'OR', name: 'Plover')

      visit '/map/?by_city_name=' + location.city.to_s + '&by_state_name=' + location.state.to_s

      expect(find('#search_results')).to have_content('Cleo')
      expect(find('#search_results')).to_not have_content('Sass')
      expect(find('#search_results')).to_not have_content('Jolene')
      expect(find('#search_results')).to_not have_content('Plover')
    end

    it 'by_state_name alone includes all locations with that state value' do
      location = FactoryBot.create(:location, region: @region, city: 'McGannyville', state: 'CA', name: 'Cleo')
      FactoryBot.create(:location, city: 'Weakerton', state: 'CA', name: 'Plover')
      FactoryBot.create(:location, city: 'Portland', state: 'OR', name: 'Sass')

      visit '/map/?by_state_name=' + location.state.to_s

      expect(find('#search_results')).to have_content('Cleo')
      expect(find('#search_results')).to_not have_content('Sass')
      expect(find('#search_results')).to have_content('Plover')
    end

    it 'by_city_no_state only includes locations that do not have a state value' do
      FactoryBot.create(:location, city: 'McGannyville', state: 'CA', name: 'Cleo')
      location = FactoryBot.create(:location, city: 'McGannyville', state: '', name: 'Sass')
      FactoryBot.create(:location, city: 'McGannyville', state: 'TX', name: 'Jolene')
      FactoryBot.create(:location, city: 'Weakerton', state: 'OR', name: 'Plover')

      visit '/map/?by_city_no_state=' + location.city.to_s

      expect(find('#search_results')).to_not have_content('Cleo')
      expect(find('#search_results')).to have_content('Sass')
      expect(find('#search_results')).to_not have_content('Jolene')
      expect(find('#search_results')).to_not have_content('Plover')
    end

    it 'by_country only includes locations from that country' do
      FactoryBot.create(:location, city: 'Americaville', state: 'CA', country: 'US', name: 'Cleo')
      FactoryBot.create(:location, city: 'Canadatown', state: 'MB', country: 'CA', name: 'Jolene')

      visit '/map/?by_country=US'

      expect(find('#search_results')).to have_content('Cleo')
      expect(find('#search_results')).to_not have_content('Jolene')
    end

    it 'by_ic_active' do
      FactoryBot.create(:location, city: 'McGannyville', state: 'TX', name: 'Jolene', ic_active: true)
      FactoryBot.create(:location, city: 'Weakerton', state: 'OR', name: 'Plover', ic_active: false)

      visit '/map/?by_ic_active=true'

      expect(find('#search_results')).to have_content('McGannyville')
      expect(find('#search_results')).to_not have_content('Weakerton')
    end

    it 'by_is_stern_army' do
      FactoryBot.create(:location, city: 'McGannyville', state: 'TX', name: 'Jolene', is_stern_army: true)
      FactoryBot.create(:location, city: 'Weakerton', state: 'OR', name: 'Plover', is_stern_army: false)

      visit '/map/?by_is_stern_army=true'

      expect(find('#search_results')).to have_content('McGannyville')
      expect(find('#search_results')).to_not have_content('Weakerton')
    end

    it 'by_machine_type' do
      machine1 = FactoryBot.create(:machine, name: 'Cool', machine_type: 'em')
      machine2 = FactoryBot.create(:machine, name: 'Uncool', machine_type: 'ss')
      location1 = FactoryBot.create(:location, region: nil, name: 'Satch Hut')
      location2 = FactoryBot.create(:location, region: nil, name: 'Polly Barn')
      FactoryBot.create(:location_machine_xref, location: location1, machine: machine1)
      FactoryBot.create(:location_machine_xref, location: location2, machine: machine2)

      visit '/map/?by_machine_type=em'

      expect(find('#search_results')).to have_content('Satch Hut')
      expect(find('#search_results')).to_not have_content('Polly Barn')
    end

    it 'by_machine_display' do
      machine1 = FactoryBot.create(:machine, name: 'Cool', machine_display: 'reels')
      machine2 = FactoryBot.create(:machine, name: 'Uncool', machine_display: 'alphanumeric')
      location1 = FactoryBot.create(:location, region: nil, name: 'Satch Hut')
      location2 = FactoryBot.create(:location, region: nil, name: 'Polly Barn')
      FactoryBot.create(:location_machine_xref, location: location1, machine: machine1)
      FactoryBot.create(:location_machine_xref, location: location2, machine: machine2)

      visit '/map/?by_machine_display=reels'

      expect(find('#search_results')).to have_content('Satch Hut')
      expect(find('#search_results')).to_not have_content('Polly Barn')
    end

    it 'by manufacturer' do
      machine1 = FactoryBot.create(:machine, name: 'Cool', manufacturer: 'Stern')
      machine2 = FactoryBot.create(:machine, name: 'Uncool', manufacturer: 'Gottlieb')
      location1 = FactoryBot.create(:location, region: nil, name: 'Satch Hut')
      location2 = FactoryBot.create(:location, region: nil, name: 'Polly Barn')
      FactoryBot.create(:location_machine_xref, location: location1, machine: machine1)
      FactoryBot.create(:location_machine_xref, location: location2, machine: machine2)

      visit '/map/?manufacturer=Stern'

      expect(find('#search_results')).to have_content('Satch Hut')
      expect(find('#search_results')).to_not have_content('Polly Barn')
    end

    it 'respects a region param and loads all region locations on initial load' do
      regionless_location = FactoryBot.create(:location, region: nil, name: 'Regionless place')
      FactoryBot.create(:location_machine_xref, location: regionless_location, machine: @machine)

      visit "/map?by_machine_id=#{@machine.id}"

      sleep 1

      expect(find('#search_results')).to have_content('Regionless place')
      expect(find('#search_results')).to have_content('Cleo')

      visit "/portland?region=portland&by_machine_id=#{@machine.id}"

      sleep 1

      expect(find('#search_results')).to_not have_content('Regionless place')
      expect(find('#search_results')).to have_content('Cleo')

      sleep 1

      visit '/portland'

      sleep 1

      expect(find('#search_results')).to_not have_content('Regionless place')
      expect(find('#search_results')).to have_content('Cleo')
    end
  end

  describe 'former_machines', type: :feature, js: true do
    before(:each) do
      @location = FactoryBot.create(:location, name: 'Cleo')
      @location2 = FactoryBot.create(:location, name: 'Sassimo')
    end
    it 'returns a list of machines that have been removed from the location' do
      FactoryBot.create(:user_submission, created_at: '2022-01-02', location: @location, machine_name: 'Sassy Madness', submission_type: UserSubmission::REMOVE_MACHINE_TYPE)
      FactoryBot.create(:user_submission, created_at: '2022-01-02', location: @location2, machine_name: 'Pizza Attack', submission_type: UserSubmission::REMOVE_MACHINE_TYPE)

      visit '/map/?by_location_id=' + @location.id.to_s

      find("#former_machines_location_banner_#{@location.id}").click
      sleep(0.5)

      expect(find('.former_machines_location')).to have_content('Sassy Madness')
      expect(find('.former_machines_location')).to_not have_content('Pizza Attack')
    end
  end

  describe 'recent_activity', type: :feature, js: true do
    before(:each) do
      @location = FactoryBot.create(:location, name: 'Cleo', city: 'Townville')
      @location2 = FactoryBot.create(:location, name: 'Sassimo')
    end
    it 'returns a list of recent activity at the location' do
      FactoryBot.create(:user_submission, created_at: '2022-01-02', location: @location, user_name: 'ssw', machine_name: 'Sassy Madness', submission_type: UserSubmission::NEW_LMX_TYPE)
      FactoryBot.create(:user_submission, created_at: '2022-01-03', location: @location, user_name: 'ssw', machine_name: 'Pizza Attack', submission_type: UserSubmission::REMOVE_MACHINE_TYPE)
      FactoryBot.create(:user_submission, created_at: '2022-01-04', location: @location, user_name: 'ssw', comment: 'be best', machine_name: 'Sassy Madness', submission_type: UserSubmission::NEW_CONDITION_TYPE)
      FactoryBot.create(:user_submission, created_at: '2022-01-05', location: @location, user_name: 'ssw', submission_type: UserSubmission::CONFIRM_LOCATION_TYPE)
      FactoryBot.create(:user_submission, created_at: '2022-01-06', location: @location, user_name: 'ssw', high_score: '2222', machine_name: 'Sassy Madness', submission_type: UserSubmission::NEW_SCORE_TYPE)
      FactoryBot.create(:user_submission, created_at: '2022-01-02', location: @location2, machine_name: 'Jolene Zone', submission_type: UserSubmission::REMOVE_MACHINE_TYPE)
      FactoryBot.create(:user_submission, created_at: '2022-01-06', location: @location, user_name: 'ssw', comment: 'hello there', machine_name: 'Sassy Madness', submission_type: UserSubmission::NEW_CONDITION_TYPE, deleted_at: '2022-01-06')

      visit '/map/?by_location_id=' + @location.id.to_s

      find("#recent_location_activity_location_banner_#{@location.id}").click
      sleep(0.5)

      expect(find('.recent_location_activity_location')).to have_content('added')
      expect(find('.recent_location_activity_location')).to have_content('removed')
      expect(find('.recent_location_activity_location')).to_not have_content('score')
      expect(find('.recent_location_activity_location')).to_not have_content('hello there')
      expect(find('.recent_location_activity_location')).to have_content('confirmed')
      expect(find('.recent_location_activity_location')).to have_content('be best')
      expect(find('.recent_location_activity_location')).to_not have_content('Jolene Zone')
    end
  end

  describe 'update_metadata', type: :feature, js: true do
    before(:each) do
      @user = FactoryBot.create(:user)
      login(@user)

      @location = FactoryBot.create(:location, region: @region, name: 'Cleo')
    end

    it 'regioned page: only allows you to pick regionless operators or operators in your region' do
      FactoryBot.create(:operator, region: nil, name: 'Regionless operator')
      FactoryBot.create(:operator, region: @region, name: 'Quarterworld')

      FactoryBot.create(:operator, region: FactoryBot.create(:region, name: 'la'), name: 'Other region operator')

      visit '/portland/?by_location_id=' + @location.id.to_s

      find('.meta_image').click
      expect(page).to have_select("new_operator_#{@location.id}", with_options: [ 'Quarterworld', 'Regionless operator' ])
    end

    it 'regionless page: lets you pick any operator' do
      FactoryBot.create(:operator, region: nil, name: 'Regionless operator')
      FactoryBot.create(:operator, region: @region, name: 'Quarterworld')
      FactoryBot.create(:operator, region: FactoryBot.create(:region, name: 'la'), name: 'Other region operator')

      regionless_location = FactoryBot.create(:location, region: nil, name: 'Regionless')

      visit '/map/?by_location_id=' + regionless_location.id.to_s

      find('.meta_image').click
      expect(page).to have_select("new_operator_#{regionless_location.id}", with_options: [ 'Other region operator', 'Quarterworld', 'Regionless operator' ])
    end

    it 'does not save data if any formats are invalid - website and phone' do
      o = FactoryBot.create(:operator, region: @location.region, name: 'Quarterworld')

      visit '/portland/?by_location_id=' + @location.id.to_s

      find('.meta_image').click
      fill_in('new_phone_' + @location.id.to_s, with: 'THIS IS INVALID')
      fill_in('new_website_' + @location.id.to_s, with: 'http://www.pinballmap.com')
      select('Quarterworld', from: "new_operator_#{@location.id}")
      click_on 'Save'

      sleep 1

      expect(@location.reload.operator_id).to eq(o.id)
      expect(@location.phone).to eq(nil)
      expect(@location.website).to eq('http://www.pinballmap.com')
      expect(page).to have_content('Invalid phone format.')

      t = FactoryBot.create(:location_type, name: 'Bar')

      visit '/portland/?by_location_id=' + @location.id.to_s

      find('.meta_image').click
      fill_in("new_phone_#{@location.id}", with: '503-488-1938')
      fill_in("new_website_#{@location.id}", with: 'www.foo.com')
      select('Bar', from: "new_location_type_#{@location.id}")
      click_on 'Save'

      sleep 1

      expect(@location.reload.location_type_id).to eq(t.id)
      expect(@location.phone).to eq('503-488-1938')
      expect(@location.website).to eq('http://www.pinballmap.com')
      expect(page).to have_content('must begin with http:// or https://')
    end

    it 'does not save spam - website and phone' do
      visit '/portland/?by_location_id=' + @location.id.to_s

      find('.meta_image').click
      fill_in("new_phone_#{@location.id}", with: 'THIS IS SPAM')
      click_on 'Save'

      sleep 1

      expect(@location.reload.phone).to eq(nil)

      visit '/portland/?by_location_id=' + @location.id.to_s

      find('.meta_image').click
      fill_in("new_phone_#{@location.id}", with: '')
      fill_in("new_website_#{@location.id}", with: 'THIS IS SPAM')
      click_on 'Save'

      sleep 1

      expect(@location.reload.website).to eq(nil)
    end

    it 'allows users to update a location metadata - stubbed out spam detection' do
      t = FactoryBot.create(:location_type, name: 'Bar')
      o = FactoryBot.create(:operator, region: @location.region, name: 'Quarterworld')

      visit '/portland/?by_location_id=' + @location.id.to_s

      find('.meta_image').click
      fill_in("new_website_#{@location.id}", with: 'http://www.foo.com')
      fill_in("new_phone_#{@location.id}", with: '503-285-3928')
      select('Bar', from: "new_location_type_#{@location.id}")
      select('Quarterworld', from: "new_operator_#{@location.id}")
      click_on 'Save'

      sleep 1

      expect(@location.reload.website).to eq('http://www.foo.com')
      expect(@location.phone).to eq('503-285-3928')
      expect(@location.operator_id).to eq(o.id)
      expect(@location.location_type_id).to eq(t.id)
      expect(@location.date_last_updated.strftime('%b %d, %Y')).to eq(Time.now.strftime('%b %d, %Y'))
      expect(@location.last_updated_by_user).to eq(@user)

      expect(page).to_not have_css('div#flash_error')
      expect(page).to have_content("Last updated: #{Time.now.strftime('%b %d, %Y')}")
    end

    it 'allows users to update a location metadata - TWICE' do
      visit '/portland/?by_location_id=' + @location.id.to_s

      find('.meta_image').click
      fill_in("new_website_#{@location.id}", with: 'http://www.foo.com')
      click_on 'Save'

      sleep 1

      expect(Location.find(@location.id).website).to eq('http://www.foo.com')
      expect(page).to_not have_css('div#flash_error')

      find('.meta_image').click
      fill_in("new_website_#{@location.id}", with: 'http://www.bar.com')
      click_on 'Save'

      sleep 1

      expect(Location.find(@location.id).website).to eq('http://www.bar.com')
      expect(page).to_not have_css('div#flash_error')
    end

    it 'does not allow descs with http://- stubbed out spam detection' do
      visit '/portland/?by_location_id=' + @location.id.to_s

      find("#location_detail_location_#{@location.id} .meta_image").click
      fill_in("new_desc_#{@location.id}", with: 'http://hopethisdoesntwork.com foo bar baz')
      click_on 'Save'

      sleep 1

      expect(@location.reload.description).to eq(nil)
    end

    it 'does not allow descs with https://- stubbed out spam detection' do
      visit '/portland/?by_location_id=' + @location.id.to_s

      find("#location_detail_location_#{@location.id} .meta_image").click
      fill_in("new_desc_#{@location.id}", with: 'https://hopethisdoesntwork.com foo bar baz')
      click_on 'Save'

      sleep 1

      expect(@location.reload.description).to eq(nil)
    end

    it 'allows users to update a location description - stubbed out spam detection' do
      visit '/portland/?by_location_id=' + @location.id.to_s

      find("#location_detail_location_#{@location.id} .meta_image").click
      fill_in("new_desc_#{@location.id}", with: 'COOL DESC')
      click_on 'Save'

      sleep 1

      expect(Location.find(@location.id).description).to eq('COOL DESC')
      expect(Location.find(@location.id).date_last_updated.strftime('%b %d, %Y')).to eq(Time.now.strftime('%b %d, %Y'))
      expect(Location.find(@location.id).last_updated_by_user).to eq(@user)

      expect(page).to have_content("Last updated: #{Time.now.strftime('%b %d, %Y')}")
    end

    it 'allows users to update a location description - TWICE' do
      visit '/portland/?by_location_id=' + @location.id.to_s

      find("#location_detail_location_#{@location.id} .meta_image").click
      fill_in("new_desc_#{@location.id}", with: 'COOL DESC')
      click_on 'Save'

      sleep 1

      expect(Location.find(@location.id).description).to eq('COOL DESC')

      find("#location_detail_location_#{@location.id} .meta_image").click
      fill_in("new_desc_#{@location.id}", with: 'COOLER DESC')
      click_on 'Save'

      sleep 1

      expect(Location.find(@location.id).description).to eq('COOLER DESC')
    end

    it 'allows users to update a location description - skips validation' do
      visit '/portland/?by_location_id=' + @location.id.to_s

      find("#location_detail_location_#{@location.id} .meta_image").click
      fill_in("new_desc_#{@location.id}", with: 'COOL DESC')
      click_on 'Save'

      sleep 1

      expect(@location.reload.description).to eq('COOL DESC')
    end

    it 'does not error on nil descriptions' do
      visit '/portland/?by_location_id=' + @location.id.to_s

      find("#location_detail_location_#{@location.id} .meta_image").click
      fill_in("new_desc_#{@location.id}", with: nil)
      click_on 'Save'

      sleep 1

      expect(@location.reload.description).to eq(nil)
    end

    it 'updates last updated' do
      visit '/portland/?by_location_id=' + @location.id.to_s

      find("#location_detail_location_#{@location.id} .meta_image").click
      fill_in("new_desc_#{@location.id}", with: 'coooool')
      click_on 'Save'

      sleep 1

      expect(@location.reload.description).to eq('coooool')
      expect(@location.date_last_updated).to eq(Date.today)
    end

    it 'truncates descriptions to 550 characters' do
      visit '/portland/?by_location_id=' + @location.id.to_s

      string_that_is_too_large = <<HERE
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus efficitur porta dui vel eleifend. Maecenas pulvinar varius euismod. Curabitur luctus diam quis pulvinar facilisis. Suspendisse eu felis sit amet eros cursus aliquam. Proin sit amet posuere. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus efficitur porta dui vel eleifend. Maecenas pulvinar varius euismod. Curabitur luctus diam quis pulvinar facilisis. Suspendisse eu felis sit amet eros cursus aliquam. Proin sit amet posuere. Lorem ipsum dolor sit amet, consectetur adipiscing elit.
HERE

      find("#location_detail_location_#{@location.id} .meta_image").click
      fill_in("new_desc_#{@location.id}", with: string_that_is_too_large)
      click_on 'Save'

      sleep 1

      expect(@location.reload.description).to eq('Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus efficitur porta dui vel eleifend. Maecenas pulvinar varius euismod. Curabitur luctus diam quis pulvinar facilisis. Suspendisse eu felis sit amet eros cursus aliquam. Proin sit amet posuere. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus efficitur porta dui vel eleifend. Maecenas pulvinar varius euismod. Curabitur luctus diam quis pulvinar facilisis. Suspendisse eu felis sit amet eros cursus aliquam. Proin sit amet posuere. Lorem ipsum dolor sit amet, consect')
    end
  end
end
