require 'spec_helper'

describe LocationsController do
  before(:each) do
    @region = FactoryBot.create(:region, name: 'portland', full_name: 'portland', lat: 1, lon: 2, motd: 'This is a MOTD', n_search_no: 4, should_email_machine_removal: 1)
  end

  describe 'confirm location', type: :feature, js: true do
    before(:each) do
      @user = FactoryBot.create(:user, username: 'ssw')
      page.set_rack_session("warden.user.user.key": User.serialize_into_session(@user))
    end

    [FactoryBot.create(:region, name: 'portland'), nil].each do |region|
      it 'lets you click a button to update the date_last_updated' do
        location = FactoryBot.create(:location, region: region, name: 'Cleo')

        visit "/#{region ? region.name : 'regionless'}/?by_location_id=" + location.id.to_s

        sleep 1

        find("#confirm_location_button_#{location.id} span.confirm_button").click

        sleep 1

        expect(location.reload.date_last_updated).to eq(Date.today)
        expect(find("#last_updated_location_#{location.id}")).to have_content("Location last updated: #{Time.now.strftime('%b-%d-%Y')} by ssw")
        expect(URI.parse(page.find_link('ssw')['href']).to_s).to match(%r{\/users\/#{@user.username}\/profile})
      end
    end

    it 'displays no username when it was last updated by a non-user' do
      location = FactoryBot.create(:location, region_id: @region.id, name: 'Cleo')

      location.date_last_updated = Date.today
      location.save(validate: false)

      visit '/portland/?by_location_id=' + location.id.to_s

      expect(find("#last_updated_location_#{location.id}")).to have_content("Location last updated: #{Time.now.strftime('%b-%d-%Y')}")
    end
  end

  describe 'remove machine - not authed', type: :feature, js: true do
    before(:each) do
      @location = FactoryBot.create(:location, region_id: @region.id, name: 'Cleo')
      @machine = FactoryBot.create(:machine, name: 'Bawb')

      page.set_rack_session("warden.user.user.key": nil)
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
      page.set_rack_session("warden.user.user.key": User.serialize_into_session(@user))

      @location = FactoryBot.create(:location, region_id: @region.id, name: 'Cleo')
      @machine = FactoryBot.create(:machine, name: 'Bawb')
    end

    [true, false].each do |region|
      it 'removes a machine from a location' do
        region = region ? @region : nil
        location = FactoryBot.create(:location, name: 'Cleo', region: region)

        FactoryBot.create(:location_machine_xref, location: location, machine: @machine)

        if region
          expect(Pony).to receive(:mail) do |mail|
            expect(mail).to include(
              subject: 'PBM - Someone removed a machine from a location',
              to: [],
              from: 'admin@pinballmap.com'
            )
          end
        else
          expect(Pony).to_not receive(:mail)
        end

        visit "/#{region ? region.name : 'regionless'}/?by_location_id=" + location.id.to_s

        page.accept_confirm do
          click_button 'remove'
        end

        sleep 1

        expect(LocationMachineXref.all).to eq([])
        expect(location.reload.date_last_updated).to eq(Date.today)
        expect(find("#last_updated_location_#{location.id}")).to have_content("Location last updated: #{Time.now.strftime('%b-%d-%Y')}")

        expect(UserSubmission.count).to eq(2)
        submission = UserSubmission.second
        expect(submission.submission_type).to eq(UserSubmission::REMOVE_MACHINE_TYPE)

        region_submission_metadata = region ? "#{region.name} (#{region.id})" : 'REGIONLESS'
        expect(submission.submission).to eq("#{@user.username} (#{@user.id})\nCleo (2)\nBawb (1)\n#{region_submission_metadata}")
        expect(submission.user_id).to eq(User.last.id)
        expect(submission.region).to eq(location.region)
      end
    end

    it 'removes a machine from a location - allows you to cancel out of remove' do
      lmx = FactoryBot.create(:location_machine_xref, location: @location, machine: @machine)

      expect(Pony).to_not receive(:mail)

      visit '/portland/?by_location_id=' + @location.id.to_s

      page.dismiss_confirm do
        click_button 'remove'
      end

      sleep 1

      expect(LocationMachineXref.all).to eq([lmx])
    end
  end

  describe 'search locations', type: :feature, js: true do
    before(:each) do
    end

    [true, false].each do |region|
      it 'sets title and description appropriately if one location is returned' do
        region = region ? @region : nil
        FactoryBot.create(:location, region: region, name: 'Cleo')

        location = FactoryBot.create(:location, region: region, name: 'Zelda', street: '1234 Foo St.', city: 'Portland', zip: '97203')
        machine = FactoryBot.create(:machine, name: 'Bawb')
        FactoryBot.create(:location_machine_xref, location: location, machine: machine)

        old_style_title = "#{region ? region.name + ' ' : ''}Pinball Map"
        single_location_title = "Zelda - #{region ? region.name + ' ' : ''}Pinball Map"
        old_style_description = "Find local places to play pinball! The #{region ? region.name + ' ' : ''}Pinball Map is a high-quality user-updated pinball locator for all the public pinball machines in your area."
        single_location_description = 'Zelda on Pinball Map! 1234 Foo St., Portland, OR, 97203. Zelda has 1 pinball machine: Bawb.'

        visit "/#{region ? region.name : 'regionless'}"

        desc_tag = "meta[name=\"description\"][content=\"#{old_style_description}\"]"
        og_desc_tag = "meta[property=\"og:description\"][content=\"#{old_style_description}\"]"
        og_title_tag = "meta[property=\"og:title\"][content=\"#{old_style_title}\"]"

        expect(page.title).to eq("#{region ? region.name + ' ' : ''}Pinball Map")
        expect(page.body).to have_css(desc_tag, visible: false)
        expect(page.body).to have_css(og_title_tag, visible: false)
        expect(page.body).to have_css(og_desc_tag, visible: false)

        fill_in('by_location_name', with: 'Zelda')
        click_on 'location_search_button'

        sleep 1

        desc_tag = "meta[name=\"description\"][content=\"#{single_location_description}\"]"
        og_desc_tag = "meta[property=\"og:description\"][content=\"#{single_location_description}\"]"
        og_title_tag = "meta[property=\"og:title\"][content=\"#{single_location_title}\"]"
        expect(page.title).to eq(single_location_title)
        expect(page.body).to have_css(desc_tag, visible: false)
        expect(page.body).to have_css(og_desc_tag, visible: false)
        expect(page.body).to have_css(og_title_tag, visible: false) if region

        fill_in('by_location_name', with: '')
        click_on 'location_search_button'

        sleep 1

        desc_tag = "meta[name=\"description\"][content=\"#{old_style_description}\"]"
        og_desc_tag = "meta[property=\"og:description\"][content=\"#{old_style_description}\"]"
        title_tag = "meta[property=\"og:title\"][content=\"#{old_style_title}\"]"
        expect(page.title).to eq("#{region ? region.name + ' ' : ''}Pinball Map")
        expect(page.body).to have_css(desc_tag, visible: false)
        expect(page.body).to have_css(title_tag, visible: false)
        expect(page.body).to have_css(og_desc_tag, visible: false)
      end
    end

    it 'displays the number of machines returned in a search' do
      cleo_location = FactoryBot.create(:location, region: @region, name: 'Cleo')
      FactoryBot.create(:location, region: @region, name: 'Zelda')

      visit '/portland'

      click_on 'location_search_button'

      within('div#search_results') do
        expect(page).to have_content('2 Locations in Results')
      end

      visit '/portland/?by_location_id=' + cleo_location.id.to_s

      within('div#search_results') do
        expect(page).to_not have_content('1 Location in Results')
      end
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

      expect(page).to have_content("NOT FOUND IN THIS REGION. PLEASE SEARCH AGAIN.\nUse the dropdown or the autocompleting textbox if you want results.")
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

    it 'provides a "link to results" link filtered appropriately by region (or not)' do
      visit '/portland'

      click_on 'location_search_button'

      sleep 1

      expect(URI.parse(page.find_link('Link to this Search Result', match: :first)['href']).to_s).to match(/portland\?utf8=%E2%9C%93&region=portland&by_location_id=&by_location_name=/)

      visit '/regionless'

      click_on 'location_search_button'

      sleep 1

      expect(URI.parse(page.find_link('Link to this Search Result', match: :first)['href']).to_s).to match(/regionless\?utf8=%E2%9C%93&by_machine_id=&by_location_id=&by_machine_name=&address=&by_location_name=/)
    end

    it 'respects a region param' do
      regionless_location = FactoryBot.create(:location, region: nil, name: 'Regionless place')
      FactoryBot.create(:location_machine_xref, location: regionless_location, machine: @machine)

      visit "/regionless?utf8=%E2%9C%93&by_location_id=&by_location_name=&by_machine_id=#{@machine.id}"

      sleep 1

      expect(find('#search_results')).to have_content('Regionless place')
      expect(find('#search_results')).to have_content('Cleo')

      visit "/portland?utf8=%E2%9C%93&region=portland&by_location_id=&by_location_name=&by_machine_id=#{@machine.id}"

      sleep 1

      expect(find('#search_results')).to_not have_content('Regionless place')
      expect(find('#search_results')).to have_content('Cleo')
    end

    it 'respects a region param -- does not start a search just based on presense of region' do
      visit '/portland'

      sleep 1

      expect(page).not_to have_selector('#search_results')
    end
  end

  describe 'update_metadata', type: :feature, js: true do
    before(:each) do
      @user = FactoryBot.create(:user)
      page.set_rack_session("warden.user.user.key": User.serialize_into_session(@user))

      @location = FactoryBot.create(:location, region: @region, name: 'Cleo')
    end

    it 'does not save data if any formats are invalid - website and phone' do
      stub_const('ENV', 'RAKISMET_KEY' => 'asdf')

      expect(Rakismet).to receive(:akismet_call).twice.and_return('false')

      o = FactoryBot.create(:operator, region: @location.region, name: 'Quarterworld')

      visit '/portland/?by_location_id=' + @location.id.to_s

      find('.location_meta span.meta_image').click
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

      find('.location_meta span.meta_image').click
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
      stub_const('ENV', 'RAKISMET_KEY' => 'asdf')

      expect(Rakismet).to receive(:akismet_call).twice.and_return('true')

      visit '/portland/?by_location_id=' + @location.id.to_s

      find('.location_meta span.meta_image').click
      fill_in("new_phone_#{@location.id}", with: 'THIS IS SPAM')
      click_on 'Save'

      sleep 1

      expect(@location.reload.phone).to eq(nil)

      visit '/portland/?by_location_id=' + @location.id.to_s

      find('.location_meta .meta_image').click
      fill_in("new_phone_#{@location.id}", with: '')
      fill_in("new_website_#{@location.id}", with: 'THIS IS SPAM')
      click_on 'Save'

      sleep 1

      expect(@location.reload.website).to eq('')
    end

    it 'allows users to update a location metadata - stubbed out spam detection' do
      t = FactoryBot.create(:location_type, name: 'Bar')
      o = FactoryBot.create(:operator, region: @location.region, name: 'Quarterworld')

      visit '/portland/?by_location_id=' + @location.id.to_s

      find('.location_meta span.meta_image').click
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
      expect(@location.date_last_updated.strftime('%b-%d-%Y')).to eq(Time.now.strftime('%b-%d-%Y'))
      expect(@location.last_updated_by_user).to eq(@user)

      expect(page).to_not have_css('div#flash_error')
      expect(page).to have_content("Location last updated: #{Time.now.strftime('%b-%d-%Y')}")
    end

    it 'allows users to update a location metadata - TWICE' do
      stub_const('ENV', 'RAKISMET_KEY' => 'asdf')

      expect(Rakismet).to receive(:akismet_call).twice.and_return('false')

      visit '/portland/?by_location_id=' + @location.id.to_s

      find('.location_meta span.meta_image').click
      fill_in("new_website_#{@location.id}", with: 'http://www.foo.com')
      click_on 'Save'

      sleep 1

      expect(Location.find(@location.id).website).to eq('http://www.foo.com')
      expect(page).to_not have_css('div#flash_error')

      find('.location_meta span.meta_image').click
      fill_in("new_website_#{@location.id}", with: 'http://www.bar.com')
      click_on 'Save'

      sleep 1

      expect(Location.find(@location.id).website).to eq('http://www.bar.com')
      expect(page).to_not have_css('div#flash_error')
    end
  end

  describe 'update_desc', type: :feature, js: true do
    before(:each) do
      @user = FactoryBot.create(:user)
      page.set_rack_session("warden.user.user.key": User.serialize_into_session(@user))

      @location = FactoryBot.create(:location, region: @region, name: 'Cleo')
    end

    it 'does not save spam' do
      stub_const('ENV', 'RAKISMET_KEY' => 'asdf')

      expect(Rakismet).to receive(:akismet_call).and_return('true')

      visit '/portland/?by_location_id=' + @location.id.to_s

      find("#location_detail_location_#{@location.id} .location_description .comment_image").click
      fill_in("new_desc_#{@location.id}", with: 'THIS IS SPAM')
      click_on 'Save'

      sleep 1

      expect(@location.reload.description).to eq(nil)
    end

    it 'does not allow descs with http://- stubbed out spam detection' do
      visit '/portland/?by_location_id=' + @location.id.to_s

      find("#location_detail_location_#{@location.id} .location_description .comment_image").click
      fill_in("new_desc_#{@location.id}", with: 'http://hopethisdoesntwork.com foo bar baz')
      click_on 'Save'

      sleep 1

      expect(@location.reload.description).to eq(nil)
    end

    it 'does not allow descs with https://- stubbed out spam detection' do
      visit '/portland/?by_location_id=' + @location.id.to_s

      find("#location_detail_location_#{@location.id} .location_description .comment_image").click
      fill_in("new_desc_#{@location.id}", with: 'https://hopethisdoesntwork.com foo bar baz')
      click_on 'Save'

      sleep 1

      expect(@location.reload.description).to eq(nil)
    end

    it 'allows users to update a location description - stubbed out spam detection' do
      visit '/portland/?by_location_id=' + @location.id.to_s

      find("#location_detail_location_#{@location.id} .location_description .comment_image").click
      fill_in("new_desc_#{@location.id}", with: 'COOL DESC')
      click_on 'Save'

      sleep 1

      expect(Location.find(@location.id).description).to eq('COOL DESC')
      expect(Location.find(@location.id).date_last_updated.strftime('%b-%d-%Y')).to eq(Time.now.strftime('%b-%d-%Y'))
      expect(Location.find(@location.id).last_updated_by_user).to eq(@user)

      expect(page).to have_content("Location last updated: #{Time.now.strftime('%b-%d-%Y')}")
    end

    it 'allows users to update a location description - TWICE' do
      visit '/portland/?by_location_id=' + @location.id.to_s

      find("#location_detail_location_#{@location.id} span.comment_image").click
      fill_in("new_desc_#{@location.id}", with: 'COOL DESC')
      click_on 'Save'

      sleep 1

      expect(Location.find(@location.id).description).to eq('COOL DESC')

      find("#location_detail_location_#{@location.id} span.comment_image").click
      fill_in("new_desc_#{@location.id}", with: 'COOLER DESC')
      click_on 'Save'

      sleep 1

      expect(Location.find(@location.id).description).to eq('COOLER DESC')
    end

    it 'allows users to update a location description - skips validation' do
      visit '/portland/?by_location_id=' + @location.id.to_s

      find("#location_detail_location_#{@location.id} .location_description .comment_image").click
      fill_in("new_desc_#{@location.id}", with: 'COOL DESC')
      click_on 'Save'

      sleep 1

      expect(@location.reload.description).to eq('COOL DESC')
    end

    it 'does not error on nil descriptions' do
      visit '/portland/?by_location_id=' + @location.id.to_s

      find("#location_detail_location_#{@location.id} .location_description .comment_image").click
      fill_in("new_desc_#{@location.id}", with: nil)
      click_on 'Save'

      sleep 1

      expect(@location.reload.description).to eq('')
    end

    it 'updates location last updated' do
      visit '/portland/?by_location_id=' + @location.id.to_s

      find("#location_detail_location_#{@location.id} .location_description .comment_image").click
      fill_in("new_desc_#{@location.id}", with: 'coooool')
      click_on 'Save'

      sleep 1

      expect(@location.reload.description).to eq('coooool')
      expect(@location.date_last_updated).to eq(Date.today)
    end

    it 'truncates descriptions to 255 characters' do
      visit '/portland/?by_location_id=' + @location.id.to_s

      string_that_is_too_large = <<HERE
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus efficitur porta dui vel eleifend. Maecenas pulvinar varius euismod. Curabitur luctus diam quis pulvinar facilisis. Suspendisse eu felis sit amet eros cursus aliquam. Proin sit amet posuere.
HERE

      find("#location_detail_location_#{@location.id} .location_description .comment_image").click
      fill_in("new_desc_#{@location.id}", with: string_that_is_too_large)
      click_on 'Save'

      sleep 1

      expect(@location.reload.description).to eq('Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus efficitur porta dui vel eleifend. Maecenas pulvinar varius euismod. Curabitur luctus diam quis pulvinar facilisis. Suspendisse eu felis sit amet eros cursus aliquam. Proin sit amet posuer')
    end
  end
end
