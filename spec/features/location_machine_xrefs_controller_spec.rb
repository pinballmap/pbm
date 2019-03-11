require 'spec_helper'

describe LocationMachineXrefsController do
  before(:each) do
    @region = FactoryBot.create(:region, name: 'portland', full_name: 'Portland')
    @location = FactoryBot.create(:location, id: 1, region: @region)
  end

  describe 'add machines - not authed', type: :feature, js: true do
    it 'Should not allow you to add machines if you are not logged in' do
      sleep 1
      visit "/#{@region.name}/?by_location_id=#{@location.id}"
      sleep 1

      expect(page).to_not have_selector("#add_machine_location_banner_#{@location.reload.id}")
    end
  end

  describe 'add machines', type: :feature, js: true do
    before(:each) do
      @user = FactoryBot.create(:user)
      @machine_to_add = FactoryBot.create(:machine, name: 'Medieval Madness')
      FactoryBot.create(:machine, name: 'Star Wars')

      page.set_rack_session("warden.user.user.key": User.serialize_into_session(@user))
    end

    [true, false].each do |region|
      it 'Should add by id' do
        region = region ? @region : nil
        location = FactoryBot.create(:location, id: 11, region: region)

        visit "/#{region ? region.name : 'regionless'}/?by_location_id=#{location.id}"

        find("#add_machine_location_banner_#{location.id}").click
        select(@machine_to_add.name, from: 'add_machine_by_id_11')
        click_on 'add'

        sleep 1

        expect(location.machines.size).to eq(1)
        expect(location.machines.first).to eq(@machine_to_add)
        expect(location.reload.date_last_updated).to eq(Date.today)

        expect(find("#show_machines_location_#{location.id}")).to have_content(@machine_to_add.name)
        expect(find("#gm_machines_#{location.id}")).to have_content(@machine_to_add.name)
        expect(find("#last_updated_location_#{location.id}")).to have_content("Location last updated: #{Time.now.strftime('%b-%d-%Y')}")

        expect(LocationMachineXref.where(location_id: location.id, machine_id: @machine_to_add.id).first.user_id).to eq(@user.id)

        user_submission = UserSubmission.first
        expect(user_submission.user_id).to eq(@user.id)
        expect(user_submission.region).to eq(region)
        expect(user_submission.submission_type).to eq(UserSubmission::NEW_LMX_TYPE)
        expect(user_submission.submission).to eq("User #{@user.username} (#{@user.email}) added #{@machine_to_add.name} to #{location.name}")
      end
    end

    it 'Should add by name of existing machine' do
      visit "/#{@region.name}/?by_location_id=#{@location.id}"

      find("#add_machine_location_banner_#{@location.id}").click
      fill_in('add_machine_by_name_1', with: @machine_to_add.name)
      click_on 'add'

      sleep 1

      expect(@location.machines.size).to eq(1)
      expect(@location.machines.first).to eq(@machine_to_add)

      expect(find("#show_machines_location_#{@location.id}")).to have_content(@machine_to_add.name)

      visit "/#{@region.name}/?by_location_id=#{@location.id}"

      find("#add_machine_location_banner_#{@location.id}").click
      fill_in('add_machine_by_name_1', with: @machine_to_add.name.downcase)
      click_on 'add'

      sleep 1

      expect(@location.machines.size).to eq(1)
      expect(@location.machines.first).to eq(@machine_to_add)

      expect(find("#show_machines_location_#{@location.id}")).to have_content(@machine_to_add.name)
    end

    it 'Should add by name of new machine' do
      visit "/#{@region.name}/?by_location_id=#{@location.id}"

      find("#add_machine_location_banner_#{@location.id}").click
      fill_in('add_machine_by_name_1', with: 'New Machine Name')
      click_on 'add'

      sleep 1

      expect(@location.machines.size).to eq(1)
      expect(@location.machines.first.name).to eq('New Machine Name')

      expect(find("#show_machines_location_#{@location.id}")).to have_content('New Machine Name')
    end

    it 'should display year/manufacturer where appropriate in dropdown' do
      FactoryBot.create(:machine, name: 'Wizard of Oz')
      FactoryBot.create(:machine, name: 'X-Men', manufacturer: 'stern')
      FactoryBot.create(:machine, name: 'Dirty Harry', year: 2001)
      FactoryBot.create(:machine, name: 'Fireball', manufacturer: 'bally', year: 2000)

      visit "/#{@region.name}/?by_location_id=#{@location.id}"

      find("#add_machine_location_banner_#{@location.id}").click

      expect(page).to have_select('add_machine_by_id_1', with_options: [
        'Wizard of Oz',
        'X-Men (stern)',
        'Dirty Harry (2001)',
        'Fireball (bally, 2000)'
      ])
    end
  end

  describe 'feeds', type: :feature, js: true do
    it 'Should only display the last 50 machines in the feed' do
      old_machine = FactoryBot.create(:machine, name: 'Spider-Man')
      recent_machine = FactoryBot.create(:machine, name: 'Twilight Zone')

      FactoryBot.create(:location_machine_xref, location: @location, machine: old_machine)
      50.times { FactoryBot.create(:location_machine_xref, location: @location, machine: recent_machine) }

      visit "/#{@region.name}/location_machine_xrefs.rss"

      expect(page.body).to have_content('Twilight Zone')
      expect(page.body).to_not have_content('Spider-Man')
    end
  end

  describe 'machine descriptions - no auth', type: :feature, js: true do
    before(:each) do
      @lmx = FactoryBot.create(:location_machine_xref, location: @location, machine: FactoryBot.create(:machine))
    end

    it 'does not let you edit machine descriptions' do
      visit '/portland/?by_location_id=' + @location.id.to_s

      sleep 1

      expect(page).to_not have_selector('span.condition_button.condition_button_new')
      page.find("div#desc_show_location_#{@location.id}").click
      expect(page).to_not have_content('Cancel')
    end
  end

  describe 'machine descriptions', type: :feature, js: true do
    before(:each) do
      @lmx = FactoryBot.create(:location_machine_xref, location: @location, machine: FactoryBot.create(:machine))
      @user = FactoryBot.create(:user, id: 11, username: 'ssw', email: 'foo@bar.com')

      page.set_rack_session("warden.user.user.key": User.serialize_into_session(@user))
    end

    it 'does not save spam' do
      stub_const('ENV', 'RAKISMET_KEY' => 'asdf', 'MAPBOX_DEV_API_KEY' => ENV['MAPBOX_DEV_API_KEY'])

      expect(Rakismet).to receive(:akismet_call).and_return('true')

      visit '/portland/?by_location_id=' + @location.id.to_s

      page.find("div#machine_condition_lmx_#{@lmx.id}.machine_condition_lmx span.comment_image").click
      fill_in("new_machine_condition_#{@lmx.id}", with: 'THIS IS SPAM')
      page.find("input#save_machine_condition_#{@lmx.id}").click

      sleep 1

      expect(@lmx.reload.condition).to eq(nil)
    end

    it 'does not save conditions with <a href in it' do
      visit '/portland/?by_location_id=' + @location.id.to_s

      page.find("div#machine_condition_lmx_#{@lmx.id}.machine_condition_lmx span.comment_image").click
      fill_in("new_machine_condition_#{@lmx.id}", with: 'THIS IS SPAM <a href')
      page.find("input#save_machine_condition_#{@lmx.id}").click

      sleep 1

      expect(@lmx.reload.condition).to eq(nil)
    end

    [true, false].each do |region|
      it 'allows users to update a location machine condition - stubbed out spam detection' do
        region = region ? @region : nil
        location = FactoryBot.create(:location, id: 111, region: region)

        lmx = FactoryBot.create(:location_machine_xref, location: location, machine: FactoryBot.create(:machine))
        stub_const('ENV', 'RAKISMET_KEY' => 'asdf', 'MAPBOX_DEV_API_KEY' => ENV['MAPBOX_DEV_API_KEY'])

        expect(Rakismet).to receive(:akismet_call).and_return('false')

        visit "/#{location.region ? location.region.name : 'regionless'}/?by_location_id=" + location.id.to_s

        page.find("div#machine_condition_lmx_#{lmx.id}.machine_condition_lmx span.comment_image").click
        fill_in("new_machine_condition_#{lmx.id}", with: 'THIS IS NOT SPAM')
        page.find("input#save_machine_condition_#{lmx.id}").click

        sleep 1

        expect(lmx.reload.condition).to eq('THIS IS NOT SPAM')

        user_submission = UserSubmission.last

        expect(user_submission.user_id).to eq(@user.id)
        expect(user_submission.region).to eq(location.region)
        expect(user_submission.submission_type).to eq(UserSubmission::NEW_CONDITION_TYPE)
        expect(user_submission.submission).to eq("User #{@user.username} (#{@user.email}) commented on #{lmx.machine.name} at #{lmx.location.name}. They said: THIS IS NOT SPAM")
      end
    end

    it 'should let me add a new machine description' do
      expect(Pony).to receive(:mail) do |mail|
        expect(mail[:body]).to match(/This is a new condition/)
        expect(mail[:body]).to match(/#{@lmx.machine.name}/)
        expect(mail[:body]).to match(/#{@lmx.location.name}/)
        expect(mail[:body]).to match(/portland/)
        expect(mail[:body]).to match(/entered from 127.0.0.1/)
        expect(mail[:subject]).to match(/PBM - Someone entered a machine condition/)
        expect(mail[:to]).to eq([])
        expect(mail[:from]).to eq('admin@pinballmap.com')
      end

      visit "/#{@region.name}/?by_location_id=#{@location.id}"

      page.find("div#machine_condition_lmx_#{@lmx.id}.machine_condition_lmx span.comment_image").click
      fill_in("new_machine_condition_#{@lmx.id}", with: 'This is a new condition')
      page.find("input#save_machine_condition_#{@lmx.id}.save_button").click

      sleep 1

      expect(find("#machine_condition_display_lmx_#{@lmx.id}")).to have_content("This is a new condition\nUpdated: #{@lmx.current_condition.created_at.strftime('%b-%d-%Y')} by ssw")
      expect(@lmx.reload.location.date_last_updated).to eq(Date.today)
      expect(find("#last_updated_location_#{@location.id}")).to have_content("Location last updated: #{@location.date_last_updated.strftime('%b-%d-%Y')} by ssw")
      expect(URI.parse(page.find_link('ssw', match: :first)['href']).to_s).to match(%r{\/users\/ssw\/profile})
    end

    it 'displays who updated a machine if that data is available' do
      FactoryBot.create(:machine_condition, location_machine_xref: @lmx, user: FactoryBot.create(:user, id: 10, username: 'cibw'))

      visit "/#{@region.name}/?by_location_id=#{@location.id}"

      expect(find("#machine_condition_display_lmx_#{@lmx.id}")).to have_content("Test Comment\nUpdated: #{@lmx.current_condition.created_at.strftime('%b-%d-%Y')} by cibw")
      expect(URI.parse(page.find_link('cibw')['href']).to_s).to match(%r{\/users\/cibw\/profile})
    end

    it 'does not error out if user later deleted their account' do
      FactoryBot.create(:machine_condition, location_machine_xref: @lmx, user_id: 666)

      visit "/#{@region.name}/?by_location_id=#{@location.id}"

      expect(find("#machine_condition_display_lmx_#{@lmx.id}")).to have_content("Test Comment\nUpdated: #{@lmx.current_condition.created_at.strftime('%b-%d-%Y')} by DELETED USER")
    end

    it 'only displays the 6 most recent descriptions' do
      login

      lmx = @lmx.reload
      lmx.condition = 'Condition 7'
      lmx.save

      7.times do |i|
        FactoryBot.create(:machine_condition, location_machine_xref: @lmx.reload, comment: "Condition #{i + 1}", created_at: "199#{i + 1}-01-01")
      end

      visit "/#{@region.name}/?by_location_id=#{@location.id}"

      page.find("div#show_conditions_lmx_banner_#{@lmx.id}").click

      expect(find("div#show_conditions_lmx_#{@lmx.id}.show_conditions_lmx")).to have_content('Condition 6')
      expect(find("div#show_conditions_lmx_#{@lmx.id}.show_conditions_lmx")).to have_content('Condition 5')
      expect(find("div#show_conditions_lmx_#{@lmx.id}.show_conditions_lmx")).to have_content('Condition 4')
      expect(find("div#show_conditions_lmx_#{@lmx.id}.show_conditions_lmx")).to have_content('Condition 3')
      expect(find("div#show_conditions_lmx_#{@lmx.id}.show_conditions_lmx")).to have_content('Condition 2')
      expect(find("div#show_conditions_lmx_#{@lmx.id}.show_conditions_lmx")).to have_content('Condition 1')

      page.find("div#machine_condition_lmx_#{@lmx.id}.machine_condition_lmx span.comment_image").click
      fill_in("new_machine_condition_#{@lmx.id}", with: 'This is a new condition')
      page.find("input#save_machine_condition_#{@lmx.id}").click

      expect(find("div#show_conditions_lmx_#{@lmx.id}.show_conditions_lmx")).to have_content('Condition 7')
      expect(find("div#show_conditions_lmx_#{@lmx.id}.show_conditions_lmx")).to have_content('Condition 6')
      expect(find("div#show_conditions_lmx_#{@lmx.id}.show_conditions_lmx")).to have_content('Condition 5')
      expect(find("div#show_conditions_lmx_#{@lmx.id}.show_conditions_lmx")).to have_content('Condition 4')
      expect(find("div#show_conditions_lmx_#{@lmx.id}.show_conditions_lmx")).to have_content('Condition 3')
      expect(find("div#show_conditions_lmx_#{@lmx.id}.show_conditions_lmx")).to have_content('Condition 2')
    end

    it 'should add past conditions when you add a new condition and a condition exists' do
      visit "/#{@region.name}/?by_location_id=#{@location.id}"

      page.find("div#machine_condition_lmx_#{@lmx.id}.machine_condition_lmx span.comment_image").click
      fill_in("new_machine_condition_#{@lmx.id}", with: 'test')
      page.find("input#save_machine_condition_#{@lmx.id}").click

      visit "/#{@region.name}/?by_location_id=#{@location.id}"

      page.find("div#machine_condition_lmx_#{@lmx.id}.machine_condition_lmx span.comment_image").click
      fill_in("new_machine_condition_#{@lmx.id}", with: 'This is a new condition')
      page.find("input#save_machine_condition_#{@lmx.id}").click

      expect(find("#machine_condition_display_lmx_#{@lmx.id}")).to have_content('This is a new condition')
      expect(find("#machine_condition_display_lmx_#{@lmx.id}")).to have_content('by ssw')

      page.find("div#machineconditions_container_lmx_#{@lmx.id}.machineconditions_container_lmx").click
      expect(find('.machine_condition_new_line')).to have_content('test')
      expect(find('.machine_condition_new_line')).to have_content('by ssw')
    end

    it 'adding a new blank comment does not delete old comments' do
      visit "/#{@region.name}/?by_location_id=#{@location.id}"

      page.find("div#machine_condition_lmx_#{@lmx.id}.machine_condition_lmx span.comment_image").click
      fill_in("new_machine_condition_#{@lmx.id}", with: 'test')
      page.find("input#save_machine_condition_#{@lmx.id}").click

      visit "/#{@region.name}/?by_location_id=#{@location.id}"

      page.find("div#machine_condition_lmx_#{@lmx.id}.machine_condition_lmx span.comment_image").click
      fill_in("new_machine_condition_#{@lmx.id}", with: 'This is a new condition')
      page.find("input#save_machine_condition_#{@lmx.id}").click

      visit "/#{@region.name}/?by_location_id=#{@location.id}"

      page.find("div#machine_condition_lmx_#{@lmx.id}.machine_condition_lmx span.comment_image").click
      fill_in("new_machine_condition_#{@lmx.id}", with: '')
      page.find("input#save_machine_condition_#{@lmx.id}").click

      expect(find("#machine_condition_lmx_#{@lmx.id}")).to have_content('')

      page.find("div#machineconditions_container_lmx_#{@lmx.id}.machineconditions_container_lmx").click
      expect(find("div#show_conditions_lmx_#{@lmx.id}")).to have_content('test')
      expect(page).to have_content('This is a new condition')
    end

    it 'should let me cancel adding a new machine description' do
      visit "/#{@region.name}/?by_location_id=#{@location.id}"

      page.find("div#machine_condition_lmx_#{@lmx.id}.machine_condition_lmx span.comment_image").click
      fill_in("new_machine_condition_#{@lmx.id}", with: 'This is a new condition')
      page.find("input#cancel_machine_condition_#{@lmx.id}").click

      sleep 1
    end
  end

  describe 'autocomplete', type: :feature, js: true do
    before(:each) do
      FactoryBot.create(:location_machine_xref, location: @location, machine: FactoryBot.create(:machine, year: 2010, manufacturer: 'Williams'))
    end

    it 'adds by machine name from input -- autocorrect picks via id' do
      @user = FactoryBot.create(:user)
      page.set_rack_session("warden.user.user.key": User.serialize_into_session(@user))

      FactoryBot.create(:machine, id: 10, name: 'Sassy Madness', year: 1980, manufacturer: 'Bally')
      FactoryBot.create(:machine, id: 11, name: 'Sassy Madness', year: 2010, manufacturer: 'Bally')

      visit "/#{@region.name}/?by_location_id=#{@location.id}"

      find("#add_machine_location_banner_#{@location.id}").click

      sleep(1)

      fill_in('add_machine_by_name_1', with: 'sassy')

      page.execute_script %{ $('#add_machine_by_name_1').trigger('focus') }
      page.execute_script %{ $('#add_machine_by_name_1').trigger('keydown') }

      expect(page).to have_xpath('//li[contains(text(), "Sassy Madness (Bally, 1980)")]')
      expect(page).to have_xpath('//li[contains(text(), "Sassy Madness (Bally, 2010)")]')

      find(:xpath, '//li[contains(text(), "Sassy Madness (Bally, 2010)")]').click

      click_on 'add'

      sleep(1)

      expect(@location.reload.machines.map { |m| m.name + '-' + m.year.to_s + '-' + m.manufacturer.to_s }.sort).to eq(['Sassy Madness-2010-Bally', 'Test Machine Name-2010-Williams'])
    end

    it 'adds by machine name from input' do
      @user = FactoryBot.create(:user)
      page.set_rack_session("warden.user.user.key": User.serialize_into_session(@user))

      FactoryBot.create(:machine, name: 'Sassy Madness')
      FactoryBot.create(:machine, name: 'Sassy From The Black Lagoon')
      FactoryBot.create(:machine, name: 'Cleo Game')

      visit "/#{@region.name}/?by_location_id=#{@location.id}"

      find("#add_machine_location_banner_#{@location.id}").click

      sleep(1)

      fill_in('add_machine_by_name_1', with: 'sassy')

      page.execute_script %{ $('#add_machine_by_name_1').trigger('focus') }
      page.execute_script %{ $('#add_machine_by_name_1').trigger('keydown') }

      expect(page).to have_xpath('//li[contains(text(), "Sassy From The Black Lagoon")]')
      expect(page).to have_xpath('//li[contains(text(), "Sassy Madness")]')
      expect(page).to_not have_xpath('//li[contains(text(), "Cleo Game")]')
    end

    it 'searches by machine name from input' do
      FactoryBot.create(:location_machine_xref, location: @location, machine: FactoryBot.create(:machine, name: 'Test Machine Name'))
      FactoryBot.create(:location_machine_xref, location: @location, machine: FactoryBot.create(:machine, name: 'Another Test Machine'))
      FactoryBot.create(:location_machine_xref, location: @location, machine: FactoryBot.create(:machine, name: 'Cleo'))

      visit "/#{@region.name}"

      page.find('div#other_search_options button#machine_section_link').click

      fill_in('by_machine_name', with: 'test')

      page.execute_script %{ $('#by_machine_name').trigger('focus') }
      page.execute_script %{ $('#by_machine_name').trigger('keydown') }

      expect(page).to have_xpath('//li[contains(text(), "Another Test Machine")]')
      expect(page).to have_xpath('//li[contains(text(), "Test Machine Name")]')
      expect(page).to_not have_xpath('//li[contains(text(), "Cleo")]')
    end

    it 'searches by location name from input' do
      chicago_region = FactoryBot.create(:region, name: 'chicago')

      FactoryBot.create(:location, id: 11, region: @region, name: 'Cleo North', city: 'Portland', state: 'OR')
      FactoryBot.create(:location, id: 12, region: @region, name: 'Cleo South', city: 'Vancouver', state: 'WA')
      FactoryBot.create(:location, id: 13, region: @region, name: 'Sassy')
      FactoryBot.create(:location, id: 14, region: chicago_region, name: 'Cleo West')

      visit "/#{@region.name}"

      fill_in('by_location_name', with: 'cleo')

      page.execute_script %{ $('#by_location_name').trigger('focus') }
      page.execute_script %{ $('#by_location_name').trigger('keydown') }

      expect(page).to have_xpath('//li[contains(text(), "Cleo North (Portland OR)") and @class="ui-menu-item"]')
      expect(page).to have_xpath('//li[contains(text(), "Cleo South (Vancouver WA)") and @class="ui-menu-item"]')
      expect(page).to_not have_xpath('//li[contains(text(), "Cleo West") and @class="ui-menu-item"]')
      expect(page).to_not have_xpath('//li[contains(text(), "Sassy") and @class="ui-menu-item"]')
    end

    it 'escape input' do
      FactoryBot.create(
        :location_machine_xref,
        location: FactoryBot.create(:location, id: 15, region: @region, name: 'Test[]Location'),
        machine: FactoryBot.create(:machine, name: 'Test[]Machine')
      )

      # verify that a nil search doesn't raise an exception
      visit "/#{@region.name}/machines/autocomplete"
      visit "/#{@region.name}/locations/autocomplete"

      visit "/#{@region.name}"

      fill_in('by_location_name', with: 'test[')

      page.execute_script %{ $('#by_location_name').trigger('focus') }
      page.execute_script %{ $('#by_location_name').trigger('keydown') }

      expect(page).to have_xpath('//li[contains(text(), "Test[]Location")]')

      page.find('div#other_search_options button#machine_section_link').click

      fill_in('by_machine_name', with: 'test[')

      page.execute_script %{ $('#by_machine_name').trigger('focus') }
      page.execute_script %{ $('#by_machine_name').trigger('keydown') }

      expect(page).to have_xpath('//li[contains(text(), "Test[]Machine")]')
    end

    it 'works with normal and iOS apostrophes' do
      FactoryBot.create(:location, id: 777, region: @region, name: "Clark's Castle")
      FactoryBot.create(:location, id: 778, region: @region, name: 'Clark’s Castle')

      visit "/#{@region.name}"

      fill_in('by_location_name', with: "Clark's")

      page.execute_script %{ $('#by_location_name').trigger('focus') }
      page.execute_script %{ $('#by_location_name').trigger('keydown') }

      expect(page).to have_selector('li.ui-menu-item', count: 2)

      fill_in('by_location_name', with: 'Clark’s')

      page.execute_script %{ $('#by_location_name').trigger('focus') }
      page.execute_script %{ $('#by_location_name').trigger('keydown') }

      expect(page).to have_selector('li.ui-menu-item', count: 2)
    end
  end

  describe 'main page filtering', type: :feature, js: true do
    before(:each) do
      @machine_group = FactoryBot.create(:machine_group)
      FactoryBot.create(:location_machine_xref, location: @location, machine: FactoryBot.create(:machine, name: 'Test Machine Name', machine_group: @machine_group))
    end

    it 'hides zone option when no zones in region' do
      visit "/#{@region.name}"

      expect(page).to_not have_css('button#zone_section_link')

      FactoryBot.create(:location, id: 20, region: @region, name: 'Cleo', zone: FactoryBot.create(:zone, region: @region, name: 'Alberta'))

      visit "/#{@region.name}"

      expect(page).to have_css('button#zone_section_link')
    end

    it 'hides operator option when no operators in region OR no regionless operators' do
      visit "/#{@region.name}"

      expect(page).to_not have_css('button#operator_section_link')

      FactoryBot.create(:operator, region: @region)

      visit "/#{@region.name}"

      expect(page).to have_css('button#operator_section_link')

      Operator.delete_all
      FactoryBot.create(:operator, region: nil)

      visit "/#{@region.name}"

      expect(page).to have_css('button#operator_section_link')
    end

    it 'lets you change navigation types' do
      visit "/#{@region.name}"

      expect(page).to have_css('button#location_section_link.active_section_link')
      expect(page).to_not have_css('button#machine_section_link.active_section_link')

      page.find('div#other_search_options button#machine_section_link').click

      expect(page).to_not have_css('button#location_section_link.active_section_link')
      expect(page).to have_css('button#machine_section_link.active_section_link')
    end

    it 'automatically limits searching to region' do
      chicago_region = FactoryBot.create(:region, name: 'chicago')
      FactoryBot.create(:location, id: 22, region: chicago_region, name: 'Chicago Location')

      visit "/#{@region.name}"

      page.find('input#location_search_button').click

      within('div.search_result') do
        expect(page).to have_content('Test Location Name')
        expect(page).to_not have_content('Chicago Location')
      end
    end

    it 'allows case insensive searches of a region' do
      stub_const('ENV', 'MAPBOX_DEV_API_KEY' => ENV['MAPBOX_DEV_API_KEY'])

      chicago_region = FactoryBot.create(:region, name: 'chicago', full_name: 'Chicago')
      FactoryBot.create(:location, id: 23, region: chicago_region, name: 'Chicago Location')

      visit '/CHICAGO'

      page.find('input#location_search_button').click

      within('div.search_result') do
        expect(page).to have_content('Chicago Location')
      end
    end

    it 'lets you search by machine name from select' do
      visit "/#{@region.name}"

      page.find('div#other_search_options button#machine_section_link').click

      select('Test Machine Name', from: 'by_machine_id')

      page.find('input#machine_search_button').click

      within('div.search_result') do
        expect(page).to have_content('Test Location Name')
      end
    end

    it 'lets you search by machine name from select -- returns grouped machines' do
      FactoryBot.create(:location_machine_xref, location: FactoryBot.create(:location, id: 30, name: 'Grouped Location', region: @region), machine: FactoryBot.create(:machine, name: 'Test Machine Name SE', machine_group: @machine_group))

      visit "/#{@region.name}"

      page.find('div#other_search_options button#machine_section_link').click

      select('Test Machine Name', from: 'by_machine_id')

      page.find('input#machine_search_button').click

      within('div#search_results') do
        expect(page).to have_content('Test Location Name')
        expect(page).to have_content('Grouped Location')
      end
    end

    it 'lets you search by machine name' do
      FactoryBot.create(:location_machine_xref, location: FactoryBot.create(:location, id: 31, name: 'UnGrouped Location', region: @region), machine: FactoryBot.create(:machine, name: 'No Groups'))

      visit "/#{@region.name}"

      page.find('div#other_search_options button#machine_section_link').click

      fill_in('by_machine_name', with: 'No Groups')

      page.find('input#machine_search_button').click

      within('div#search_results') do
        expect(page).to have_content('UnGrouped Location')
      end
    end

    it 'lets you search by machine name -- does not return all machines when you search for a machine that does not exist in a region' do
      visit "/#{@region.name}"

      page.find('div#other_search_options button#machine_section_link').click

      fill_in('by_machine_name', with: 'Whatever')

      page.find('input#machine_search_button').click

      expect(page).to have_content("NOT FOUND. PLEASE SEARCH AGAIN.\nUse the dropdown or the autocompleting textbox if you want results.")
      expect(page).to have_content('0 Locations & 0 Machines in Result')
    end

    it 'lets you search by machine name -- returns grouped machines' do
      FactoryBot.create(:location_machine_xref, location: FactoryBot.create(:location, id: 32, name: 'Grouped Location', region: @region), machine: FactoryBot.create(:machine, name: 'Test Machine Name SE', machine_group: @machine_group))

      visit "/#{@region.name}"

      page.find('div#other_search_options button#machine_section_link').click

      fill_in('by_machine_name', with: 'Test Machine Name')

      page.find('input#machine_search_button').click

      within('div#search_results') do
        expect(page).to have_content('Test Location Name')
        expect(page).to have_content('Grouped Location')
      end
    end

    it 'search by machine name from select is limited to machines in the region' do
      FactoryBot.create(:machine, name: 'does not exist in region')
      visit "/#{@region.name}"

      page.find('div#other_search_options button#machine_section_link').click

      expect(page).to have_select('by_machine_id', with_options: ['Test Machine Name'])
    end

    it 'automatically loads with machine detail visible on a single location search' do
      @user = FactoryBot.create(:user)
      page.set_rack_session("warden.user.user.key": User.serialize_into_session(@user))

      visit "/#{@region.name}"
      page.find('input#location_search_button').click

      expect(page).to have_content('Test Location Name')
      expect(page).to have_content('303 Southeast 3rd Avenue, Portland, OR 97214')
      expect(page).to have_content('UPLOAD A PICTURE')
      expect(page).to have_content('ADD MACHINE')
    end

    it 'searches by city' do
      FactoryBot.create(:location, id: 34, region: @region, name: 'Cleo', city: 'Portland')
      FactoryBot.create(:location, id: 35, region: @region, name: 'Bawb', city: 'Beaverton')

      visit "/#{@region.name}"

      page.find('div#other_search_options button#city_section_link').click
      select('Beaverton', from: 'by_city_id')
      page.find('input#city_search_button').click

      within('div.search_result') do
        expect(page).to have_content('Bawb')
        expect(page).to_not have_content('Cleo')
      end
    end

    it 'searches by zone' do
      FactoryBot.create(:location, id: 36, region: @region, name: 'Cleo', zone: FactoryBot.create(:zone, region: @region, name: 'Alberta'))
      FactoryBot.create(:location, id: 37, region: @region, name: 'Bawb')

      visit "/#{@region.name}"

      page.find('div#other_search_options button#zone_section_link').click
      select('Alberta', from: 'by_zone_id')
      page.find('input#zone_search_button').click

      within('div.search_result') do
        expect(page).to have_content('Cleo')
        expect(page).to_not have_content('Bawb')
      end
    end

    it 'searches by location type' do
      bar_type = FactoryBot.create(:location_type, name: 'bar')
      FactoryBot.create(:location, id: 38, region: @region, name: 'Cleo', location_type: bar_type)
      FactoryBot.create(:location, id: 39, region: @region, name: 'Bawb')
      FactoryBot.create(:location, id: 40, region: FactoryBot.create(:region), name: 'Sass', location_type: bar_type)

      visit "/#{@region.name}"

      page.find('div#other_search_options button#type_section_link').click
      select('bar', from: 'by_type_id')
      page.find('input#type_search_button').click

      within('div.search_result') do
        expect(page).to have_content('Cleo')
        expect(page).to_not have_content('Bawb')
        expect(page).to_not have_content('Sass')
      end
    end

    it 'searches by operator' do
      FactoryBot.create(:location, id: 41, region: @region, name: 'Cleo', operator: FactoryBot.create(:operator, name: 'Quarter Bean', region: @region))
      FactoryBot.create(:location, id: 42, region: @region, name: 'Bawb')

      visit "/#{@region.name}"

      page.find('div#other_search_options button#operator_section_link').click
      select('Quarter Bean', from: 'by_operator_id')
      page.find('input#operator_search_button').click

      within('div.search_result') do
        expect(page).to have_content('Cleo')
        expect(page).to_not have_content('Bawb')
      end
    end

    it 'searches by operator - displays website when available' do
      l = FactoryBot.create(:location, id: 43, region: @region, name: 'Cleo', operator: FactoryBot.create(:operator, name: 'Quarter Bean', region: @region, website: 'website.com'))

      visit "/#{@region.name}?by_location_id=#{l.reload.id}"

      sleep(1)

      expect(page).to have_content('Cleo')
      expect(page).to have_link('Quarter Bean')

      l = FactoryBot.create(:location, id: 44, region: @region, name: 'Sass', operator: FactoryBot.create(:operator, name: 'Sass Bean', region: @region, website: nil))

      visit "/#{@region.name}?by_location_id=#{l.reload.id}"

      sleep(1)

      expect(page).to have_content('Sass')
      expect(page).to have_content('Sass Bean')
      expect(page).to_not have_link('Sass Bean')
    end

    it 'searches by operator - ignores operators with no locations' do
      FactoryBot.create(:location, id: 45, region: @region, name: 'Cleo', operator: FactoryBot.create(:operator, name: 'Quarter Bean', region: @region))
      FactoryBot.create(:operator, name: 'Hope This Does Not Show Up', region: @region)

      visit "/#{@region.name}"

      page.find('div#other_search_options button#operator_section_link').click

      expect(page).to have_select('by_operator_id', options: ['All', 'Quarter Bean'])
    end

    it 'displays location type for a location, if it is available' do
      FactoryBot.create(:location, id: 46, region: @region, name: 'Cleo', location_type: FactoryBot.create(:location_type, name: 'bar'))
      FactoryBot.create(:location, id: 47, region: @region, name: 'Bawb')

      visit "/#{@region.name}"

      page.find('input#location_search_button').click

      expect(page).to have_content("Cleo\n(bar)")
      expect(page).to have_content('Bawb')
    end

    it 'displays appropriate values in location description' do
      stub_const('ENV', 'MAPBOX_DEV_API_KEY' => ENV['MAPBOX_DEV_API_KEY'])

      @user = FactoryBot.create(:user)
      page.set_rack_session("warden.user.user.key": User.serialize_into_session(@user))

      visit "/#{@region.name}"
      page.find('input#location_search_button').click

      page.find("#location_detail_location_#{@location.id} .location_description .comment_image").click
      fill_in("new_desc_#{@location.id}", with: 'New Condition')
      click_on("save_desc_#{@location.id}")

      expect(page).to have_content('New Condition')
    end

    it 'honors default search types for region' do
      FactoryBot.create(:region, name: 'chicago', default_search_type: 'city', full_name: 'Chicago')
      visit '/chicago'

      expect(page).to have_css('button#city_section_link.active_section_link')
    end

    it 'sorts searches by location name' do
      FactoryBot.create(:location, id: 48, region: @region, name: 'Zelda')
      FactoryBot.create(:location, id: 49, region: @region, name: 'Cleo')
      FactoryBot.create(:location, id: 50, region: @region, name: 'Bawb')

      visit "/#{@region.name}"
      page.find('input#location_search_button').click

      sleep(1)

      actual_order = page.all('div.search_result').map(&:text)
      expect(actual_order[0]).to match(/Bawb/)
      expect(actual_order[1]).to match(/Cleo/)
      expect(actual_order[2]).to match(/Test Machine Name/)
      expect(actual_order[3]).to match(/Zelda/)
    end

    it 'sorts searches by location name -- fuzzy search' do
      FactoryBot.create(:location, id: 48, region: @region, name: 'Zelda')
      FactoryBot.create(:location, id: 49, region: @region, name: 'Cleo')
      FactoryBot.create(:location, id: 50, region: @region, name: 'Bawb')

      visit "/#{@region.name}"
      fill_in('by_location_name', with: 'zel')
      page.find('input#location_search_button').click

      within('div#search_results') do
        expect(page).to have_content('Zelda')
      end
    end

    it 'honor N or more machines' do
      zone = FactoryBot.create(:zone, region: @region)

      cleo = FactoryBot.create(:location, id: 51, region: @region, name: 'Cleo', zone: zone)
      FactoryBot.create(:location, id: 52, region: @region, name: 'Bawb', zone: zone)

      3.times do
        FactoryBot.create(:location_machine_xref, location: cleo, machine: FactoryBot.create(:machine))
      end

      visit "/#{@region.name}"
      page.find('div#other_search_options button#zone_section_link').click
      select(2, from: 'by_at_least_n_machines_zone')
      page.find('input#zone_search_button').click

      expect(page).to have_content('Cleo')
      expect(page).to_not have_content('Bawb')
    end

    [Region.find_by_name('portland'), nil].each do |region|
      it 'honors direct link for location' do
        location = FactoryBot.create(:location, id: 111, region: region)

        visit "/#{region ? region.name : 'regionless'}/?by_location_id=#{location.id}"
        sleep(1)

        within('div.search_result') do
          expect(page).to have_content('Test Location Name')
        end
      end
    end

    it 'honors direct link for city' do
      FactoryBot.create(:location, id: 52, region: @region, name: 'Cleo', city: 'Beaverton')
      FactoryBot.create(:location, id: 53, region: @region, name: 'Bawb', city: 'Portland')

      visit "/#{@region.name}/?by_city_id=Beaverton"
      sleep(1)

      within('div.search_result') do
        expect(page).to have_content('Cleo')
        expect(page).to_not have_content('Bawb')
      end
    end

    it 'escapes characters in location address for infowindow' do
      screen_location = FactoryBot.create(:location, id: 54, region: @region, name: 'The Screen', street: "1600 St. Michael's Drive", city: "Sassy's Ville")
      lmx = FactoryBot.create(:location_machine_xref, location: screen_location, machine: FactoryBot.create(:machine))
      FactoryBot.create(:machine_condition, location_machine_xref: lmx, comment: 'cool machine description')

      visit "/#{@region.name}/?by_location_id=#{screen_location.id}"

      within('div.search_result') do
        expect(page).to have_content('The Screen')
        expect(page).to have_content('cool machine description')
      end
    end

    it 'has a machine dropdown with year and manufacturer if available' do
      FactoryBot.create(:location_machine_xref, location: FactoryBot.create(:location, id: 55, region: @region), machine: FactoryBot.create(:machine, name: 'foo', manufacturer: 'stern'))
      FactoryBot.create(:location_machine_xref, location: FactoryBot.create(:location, id: 56, region: @region), machine: FactoryBot.create(:machine, name: 'bar', year: 2000, manufacturer: 'bally'))
      FactoryBot.create(:location_machine_xref, location: FactoryBot.create(:location, id: 57, region: @region), machine: FactoryBot.create(:machine, name: 'baz', year: 2001))

      visit "/#{@region.name}"
      page.find('div#other_search_options button#machine_section_link').click

      expect(page).to have_select('by_machine_id', with_options: ['foo (stern)', 'bar (bally, 2000)', 'baz (2001)'])
    end

    it 'has location summary info that shows machine metadata when available' do
      FactoryBot.create(:location_machine_xref, location: FactoryBot.create(:location, id: 58, region: @region), machine: FactoryBot.create(:machine, name: 'foo', manufacturer: 'stern'))
      FactoryBot.create(:location_machine_xref, location: FactoryBot.create(:location, id: 59, region: @region), machine: FactoryBot.create(:machine, name: 'bar', year: 2000, manufacturer: 'bally'))
      FactoryBot.create(:location_machine_xref, location: FactoryBot.create(:location, id: 60, region: @region), machine: FactoryBot.create(:machine, name: 'baz', year: 2001))

      visit "/#{@region.name}"
      page.find('input#location_search_button').click

      expect(page).to have_content('foo (stern)')
      expect(page).to have_content('bar (bally, 2000)')
      expect(page).to have_content('baz (2001)')
    end

    it 'has ipdb links with generic or specific info when appropriate' do
      FactoryBot.create(:location_machine_xref, location: @location, machine: FactoryBot.create(:machine, name: 'foo', ipdb_link: 'http://foo.com'))
      FactoryBot.create(:location_machine_xref, location: @location, machine: FactoryBot.create(:machine, name: 'bar'))

      visit "/#{@region.name}"
      page.find('input#location_search_button').click

      sleep(1)

      expect(URI.parse(page.find_link('foo')['href']).to_s).to eq('http://foo.com/')
      expect(URI.parse(page.find_link('bar')['href']).to_s).to eq('http://ipdb.org/search.pl?name=bar;qh=checked;searchtype=advanced')
    end
  end
end
