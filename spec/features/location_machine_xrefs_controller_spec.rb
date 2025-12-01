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
      @user = FactoryBot.create(:user, email: 'ssw@bar.com', region: @region)
      @machine_to_add = FactoryBot.create(:machine, name: 'Medieval Madness')
      FactoryBot.create(:machine, name: 'Star Wars')

      login(@user)
    end

    [ true, false ].each do |region|
      it 'Should add by id' do
        region = region ? @region : nil
        location = FactoryBot.create(:location, id: 11, region: region)
        login(@user)

        visit "/#{region ? region.name : 'map'}/?by_location_id=#{location.id}"
        sleep 1

        find("#add_machine_location_banner_#{location.id}").click
        select(@machine_to_add.name, from: 'add_machine_by_id_11')
        click_on 'add'

        sleep 1

        expect(location.reload.machine_count).to eq(1)
        expect(location.machines.first).to eq(@machine_to_add)
        expect(location.reload.date_last_updated).to eq(Date.today)

        expect(find("#show_machines_location_#{location.id}")).to have_content(@machine_to_add.name)
        expect(find("#last_updated_location_#{location.id}")).to have_content("Last updated: #{Time.now.strftime('%b %d, %Y')}")

        expect(LocationMachineXref.where(location_id: location.id, machine_id: @machine_to_add.id).first.user_id).to eq(@user.id)

        user_submission = UserSubmission.first
        expect(user_submission.user_id).to eq(@user.id)
        expect(user_submission.region).to eq(region)
        expect(user_submission.submission_type).to eq(UserSubmission::NEW_LMX_TYPE)
        expect(user_submission.submission).to eq("#{@machine_to_add.name} was added to #{location.name} in #{location.city} by #{@user.username}")
      end
    end

    it 'Should re-add a soft-deleted lmx that was removed within 7 days ago and include scores and conditions' do
      region = region ? @region : nil
      location = FactoryBot.create(:location, id: 11, region: region)
      lmx = FactoryBot.create(:location_machine_xref, location: location, machine: @machine_to_add, id: 6660)
      lmx.update_condition('great', { user_id: @user.id })
      FactoryBot.create(:machine_score_xref, location_machine_xref: lmx, score: 3000, user: @user)

      visit "/#{region ? region.name : 'map'}/?by_location_id=#{location.id}"

      sleep 1

      page.accept_confirm do
        click_button 'Remove'
      end

      sleep 1

      expect(location.reload.machine_count).to eq(0)

      find("#add_machine_location_banner_#{location.id}").click
      fill_in('add_machine_by_name_11', with: @machine_to_add.name)
      click_on 'add'

      sleep 1

      page.find("div.machine_tools_lmx_toggle").click

      sleep 1

      expect(location.reload.machine_count).to eq(1)
      expect(location.machines.first).to eq(@machine_to_add)
      expect(location.location_machine_xrefs.first.id).to eq(6660)
      expect(page.body).to have_content('great')
      expect(page.body).to have_content('3,000')
    end

    it 'Should not re-add a soft-deleted lmx that was removed more than 7 days' do
      region = region ? @region : nil
      location = FactoryBot.create(:location, id: 11, region: region)
      lmx = FactoryBot.create(:location_machine_xref, location: location, machine: @machine_to_add, id: 6660)
      lmx.update_condition('great', { user_id: @user.id })
      FactoryBot.create(:machine_score_xref, location_machine_xref: lmx, score: 3000, user: @user)

      visit "/#{region ? region.name : 'map'}/?by_location_id=#{location.id}"

      sleep 1

      page.accept_confirm do
        click_button 'Remove'
      end

      sleep 1

      expect(location.reload.machine_count).to eq(0)

      lmx.deleted_at = Time.current - 20.days
      lmx.save

      find("#add_machine_location_banner_#{location.id}").click
      fill_in('add_machine_by_name_11', with: @machine_to_add.name)
      click_on 'add'

      sleep 1

      page.find("div.machine_tools_lmx_toggle").click

      sleep 1

      expect(location.reload.machine_count).to eq(1)
      expect(location.machines.first).to eq(@machine_to_add)
      expect(location.location_machine_xrefs.first.id).to_not eq(6660)
      expect(page.body).to_not have_content('great')
      expect(page.body).to_not have_content('3,000')
    end

    it 'Should add by name of existing machine' do
      visit "/#{@region.name}/?by_location_id=#{@location.id}"

      find("#add_machine_location_banner_#{@location.id}").click
      fill_in('add_machine_by_name_1', with: @machine_to_add.name)
      click_on 'add'

      sleep 1

      expect(@location.reload.machine_count).to eq(1)
      expect(@location.machines.first).to eq(@machine_to_add)

      expect(find("#show_machines_location_#{@location.id}")).to have_content(@machine_to_add.name)

      visit "/#{@region.name}/?by_location_id=#{@location.id}"

      find("#add_machine_location_banner_#{@location.id}").click
      fill_in('add_machine_by_name_1', with: @machine_to_add.name.downcase)
      click_on 'add'

      sleep 1

      expect(@location.machine_count).to eq(1)
      expect(@location.machines.first).to eq(@machine_to_add)

      expect(find("#show_machines_location_#{@location.id}")).to have_content(@machine_to_add.name)
    end

    it 'Should not add by name of new machine' do
      visit "/#{@region.name}/?by_location_id=#{@location.id}"

      find("#add_machine_location_banner_#{@location.id}").click
      fill_in('add_machine_by_name_1', with: 'New Machine Name')
      page.accept_alert 'Please choose a machine from the list. If the machine is not in the list, it is likely a game (e.g., a non-pinball game) that we do not include on Pinball Map. If you think the list is missing a pinball machine, please contact us.' do
        click_on 'add'
      end

      sleep 1

      expect(@location.machine_count).to eq(0)

      expect(find("#show_machines_location_#{@location.id}")).to_not have_content('New Machine Name')
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

    it 'should support an lmx machine_id when using /machine_id path and only show that machine in the feed' do
      machine_1 = FactoryBot.create(:machine, name: 'Twilight Zone', id: 1)
      machine_2 = FactoryBot.create(:machine, name: 'Hammer Time', id: 2)

      FactoryBot.create(:location_machine_xref, location: @location, machine: machine_1)
      FactoryBot.create(:location_machine_xref, location: @location, machine: machine_2)

      visit "/#{@region.name}/location_machine_xrefs/machine_id/1.rss"

      expect(page.body).to have_content('Twilight Zone')
      expect(page.body).to_not have_content('Hammer Time')
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
      expect(page).to_not have_css('comment_image')
    end
  end

  describe 'machine descriptions', type: :feature, js: true do
    before(:each) do
      @lmx = FactoryBot.create(:location_machine_xref, location: @location, machine: FactoryBot.create(:machine))
      @user = FactoryBot.create(:user, id: 11, username: 'ssw', email: 'foo@bar.com')

      login(@user)
    end

    it 'allows you to delete a machine condition if you were the one that entered it' do
      @lmx.update_condition('great', { user_id: @user.id })

      visit '/map/?by_location_id=' + @lmx.location.id.to_s
      page.find("div#machine_tools_lmx_banner_#{@lmx.id}").click

      expect(page).to have_selector("input[type=submit][value='delete']")

      page.accept_confirm do
        click_button 'delete'
      end

      sleep 1

      @lmx.reload
      expect(@lmx.machine_conditions.size).to eq(0)
    end

    it 'will not allow you to delete a machine condition if you were not the one that entered it' do
      @lmx.update_condition('great', { user_id: nil })

      visit '/map/?by_location_id=' + @lmx.location.id.to_s
      page.find("div#machine_tools_lmx_banner_#{@lmx.id}").click

      expect(page).to_not have_selector("input[type=submit][value='delete']")
    end

    it 'allows you to update a machine condition if you were the one that entered it' do
      @lmx.update_condition('great', { user_id: @user.id })

      visit '/map/?by_location_id=' + @lmx.location.id.to_s
      page.find("div#machine_tools_lmx_banner_#{@lmx.id}").click

      find('a#edit_condition_' + @lmx.machine_conditions.first.id.to_s + '.button').click
      fill_in 'comment', with: 'bad'

      page.accept_confirm do
        click_button 'Update Comment'
      end

      sleep 1

      @lmx.reload
      expect(@lmx.machine_conditions.first.comment).to eq('bad')
    end

    it 'will not allow you to update a machine condition if you were not the one that entered it' do
      @lmx.update_condition('great', { user_id: nil })

      visit '/map/?by_location_id=' + @lmx.location.id.to_s
      page.find("div#machine_tools_lmx_banner_#{@lmx.id}").click

      expect(page).to_not have_selector('a#edit_condition_' + @lmx.machine_conditions.first.id.to_s + '.button')
    end

    it 'does not save conditions with <a href in it' do
      visit '/portland/?by_location_id=' + @location.id.to_s

      page.find("div#machine_tools_lmx_banner_#{@lmx.id}").click
      page.find("div#machine_condition_lmx_#{@lmx.id}.machine_condition_lmx .add_condition").click
      fill_in("new_machine_condition_#{@lmx.id}", with: 'THIS IS SPAM <a href')
      page.find("input#save_machine_condition_#{@lmx.id}").click

      sleep 1

      @lmx.reload
      expect(@lmx.machine_conditions.size).to eq(0)
    end

    it 'allows users to update a location machine condition' do
      region = region ? @region : nil
      location = FactoryBot.create(:location, id: 111, region: region)

      lmx = FactoryBot.create(:location_machine_xref, location: location, machine: FactoryBot.create(:machine))

      visit "/#{location.region ? location.region.name : 'map'}/?by_location_id=" + location.id.to_s

      page.find("div#machine_tools_lmx_banner_#{lmx.id}").click
      page.find("div#machine_condition_lmx_#{lmx.id}.machine_condition_lmx .add_condition").click
      fill_in("new_machine_condition_#{lmx.id}", with: 'THIS IS NOT SPAM')
      page.find("input#save_machine_condition_#{lmx.id}").click

      sleep 1

      expect(lmx.reload.machine_conditions.first.comment).to eq('THIS IS NOT SPAM')

      user_submission = UserSubmission.last

      expect(user_submission.user_id).to eq(@user.id)
      expect(user_submission.region).to eq(location.region)
      expect(user_submission.submission_type).to eq(UserSubmission::NEW_CONDITION_TYPE)
      expect(user_submission.submission).to eq("#{@user.username} commented on #{lmx.machine.name} at #{lmx.location.name} in #{lmx.location.city}. They said: THIS IS NOT SPAM")
    end

    it 'should let me add a new machine description' do
      visit "/#{@region.name}/?by_location_id=#{@location.id}"

      page.find("div#machine_tools_lmx_banner_#{@lmx.id}").click
      page.find("div#machine_condition_lmx_#{@lmx.id}.machine_condition_lmx .add_condition").click
      fill_in("new_machine_condition_#{@lmx.id}", with: 'This is a new condition')
      page.find("input#save_machine_condition_#{@lmx.id}.save_button").click

      sleep 1

      expect(find("#show_conditions_lmx_#{@lmx.id}")).to have_content("This is a new condition\nssw\n#{@lmx.created_at.strftime('%b %d, %Y')}")
      expect(@lmx.reload.location.date_last_updated).to eq(Date.today)
      expect(find("#last_updated_location_#{@location.id}")).to have_content("#{@location.date_last_updated.strftime('%b %d, %Y')} by ssw")
      expect(URI.parse(page.find_link('ssw', match: :first)['href']).to_s).to match(%r{/users/ssw/profile})
    end

    it 'displays who updated a machine if that data is available' do
      FactoryBot.create(:machine_condition, location_machine_xref: @lmx, user: FactoryBot.create(:user, id: 10, username: 'cibw'))

      visit "/#{@region.name}/?by_location_id=#{@location.id}"

      page.find("div#machine_tools_lmx_banner_#{@lmx.id}").click

      expect(find("#show_conditions_lmx_#{@lmx.id}")).to have_content("Test Comment\ncibw\n#{@lmx.created_at.strftime('%b %d, %Y')}")
      expect(URI.parse(page.find_link('cibw')['href']).to_s).to match(%r{/users/cibw/profile})
    end

    it 'does not error out if user later deleted their account' do
      FactoryBot.create(:machine_condition, location_machine_xref: @lmx, user_id: 666)

      visit "/#{@region.name}/?by_location_id=#{@location.id}"

      page.find("div#machine_tools_lmx_banner_#{@lmx.id}").click

      expect(find("#show_conditions_lmx_#{@lmx.id}")).to have_content("Test Comment\nDELETED USER\n#{@lmx.created_at.strftime('%b %d, %Y')}")
    end

    it 'only displays the 5 most recent descriptions' do
      login

      7.times do |i|
        FactoryBot.create(:machine_condition, location_machine_xref: @lmx.reload, comment: "Condition #{i + 1} words.", created_at: "199#{i + 1}-01-01")
      end

      visit "/#{@region.name}/?by_location_id=#{@location.id}"

      page.find("div#machine_tools_lmx_banner_#{@lmx.id}").click

      expect(find("div#show_conditions_lmx_#{@lmx.id}.show_conditions_lmx")).to have_content('Condition 7 words.')
      expect(find("div#show_conditions_lmx_#{@lmx.id}.show_conditions_lmx")).to have_content('Condition 6 words.')
      expect(find("div#show_conditions_lmx_#{@lmx.id}.show_conditions_lmx")).to have_content('Condition 5 words.')
      expect(find("div#show_conditions_lmx_#{@lmx.id}.show_conditions_lmx")).to have_content('Condition 4 words.')
      expect(find("div#show_conditions_lmx_#{@lmx.id}.show_conditions_lmx")).to have_content('Condition 3 words.')
      expect(find("div#show_conditions_lmx_#{@lmx.id}.show_conditions_lmx")).to_not have_content('Condition 2 words.')
      expect(find("div#show_conditions_lmx_#{@lmx.id}.show_conditions_lmx")).to_not have_content('Condition 1 words.')

      page.find("div#machine_condition_lmx_#{@lmx.id}.machine_condition_lmx .add_condition").click
      fill_in("new_machine_condition_#{@lmx.id}", with: 'This is a new condition')
      page.find("input#save_machine_condition_#{@lmx.id}").click

      sleep 1

      expect(page).to_not have_content('Condition 3 words.')
    end

    it 'should add past conditions when you add a new condition and a condition exists' do
      visit "/#{@region.name}/?by_location_id=#{@location.id}"

      page.find("div#machine_tools_lmx_banner_#{@lmx.id}").click
      page.find("div#machine_condition_lmx_#{@lmx.id}.machine_condition_lmx .add_condition").click
      fill_in("new_machine_condition_#{@lmx.id}", with: 'test')
      page.find("input#save_machine_condition_#{@lmx.id}").click

      visit "/#{@region.name}/?by_location_id=#{@location.id}"

      page.find("div#machine_tools_lmx_banner_#{@lmx.id}").click
      page.find("div#machine_condition_lmx_#{@lmx.id}.machine_condition_lmx .add_condition").click
      fill_in("new_machine_condition_#{@lmx.id}", with: 'This is a new condition')
      page.find("input#save_machine_condition_#{@lmx.id}").click

      expect(find("#show_conditions_lmx_#{@lmx.id}")).to have_content('This is a new condition')
      expect(find("#show_conditions_lmx_#{@lmx.id}")).to have_content('ssw')

      page.find("div#machineconditions_container_lmx_#{@lmx.id}.machineconditions_container_lmx").click
      expect(find("#showing_past_machine_condition_#{@lmx.id}")).to have_content('test')
      expect(find("#showing_past_machine_condition_#{@lmx.id}")).to have_content('ssw')
    end

    it 'should let me cancel adding a new machine description' do
      visit "/#{@region.name}/?by_location_id=#{@location.id}"

      page.find("div#machine_tools_lmx_banner_#{@lmx.id}").click
      page.find("div#machine_condition_lmx_#{@lmx.id}.machine_condition_lmx .add_condition").click
      fill_in("new_machine_condition_#{@lmx.id}", with: 'This is a new condition')
      page.find("input#cancel_machine_condition_#{@lmx.id}").click

      sleep 1
    end
  end

  describe 'external links', type: :feature, js: true do
    before(:each) do
      machine_links = FactoryBot.create(:machine, name: 'Twilight Zone', id: 1, opdb_id: 666)
      machine_nolinks = FactoryBot.create(:machine, name: 'Hammer Time', id: 2)

      @machine_links_lmx = FactoryBot.create(:location_machine_xref, location: @location, machine: machine_links, id: 11)
      @machine_nolinks_lmx = FactoryBot.create(:location_machine_xref, location: @location, machine: machine_nolinks, id: 12)
    end

    it 'should show a matchplay link if machine has opdb_id ' do
      visit "/#{@region.name}/?by_location_id=#{@location.id}"

      page.find("div#machine_tools_lmx_banner_#{@machine_links_lmx.id}").click

      expect(page).to have_css('.matchplay_icon')
    end

    it 'should not show a matchplay link if machine does not have opdb_id' do
      visit "/#{@region.name}/?by_location_id=#{@location.id}"

      page.find("div#machine_tools_lmx_banner_#{@machine_nolinks_lmx.id}").click

      expect(page).to_not have_css('.matchplay_icon')
    end
  end

  describe 'backglass images', type: :feature, js: true do
    before(:each) do
      machine_backglass = FactoryBot.create(:machine, name: 'Twilight Zone', id: 1, opdb_img: '/public/favicon.ico')
      machine_nobackglass = FactoryBot.create(:machine, name: 'Hammer Time', id: 2)

      @machine_backglass_lmx = FactoryBot.create(:location_machine_xref, location: @location, machine: machine_backglass, id: 11)
      @machine_nobackglass_lmx = FactoryBot.create(:location_machine_xref, location: @location, machine: machine_nobackglass, id: 12)
    end

    it 'should show a backglass image if machine has opdb_img' do
      visit "/#{@region.name}/?by_location_id=#{@location.id}"

      page.find("div#machine_tools_lmx_banner_#{@machine_backglass_lmx.id}").click

      expect(page).to have_css('.backglass_container')
    end

    it 'should not show a backglass image if machine has opdb_img' do
      visit "/#{@region.name}/?by_location_id=#{@location.id}"

      page.find("div#machine_tools_lmx_banner_#{@machine_nobackglass_lmx.id}").click

      expect(page).to_not have_css('.backglass_container')
    end
  end

  describe 'insider connected', type: :feature, js: true do
    before(:each) do
      @user = FactoryBot.create(:user, id: 11, username: 'ssw', email: 'foo@bar.com')

      login(@user)
    end

    it 'only show button on eligible machines' do
      @lmx = FactoryBot.create(:location_machine_xref, location: @location, machine: FactoryBot.create(:machine, id: 10, year: 2010, manufacturer: 'Williams', ic_eligible: true))
      @lmx2 = FactoryBot.create(:location_machine_xref, location: @location, machine: FactoryBot.create(:machine, id: 11, year: 2011, manufacturer: 'Williams', ic_eligible: false))

      visit '/portland/?by_location_id=' + @location.id.to_s
      page.find("div#machine_tools_lmx_banner_#{@lmx.id}").click

      expect(page).to have_css('.ic_button', count: 1)
    end

    it 'initial state is null' do
      @lmx = FactoryBot.create(:location_machine_xref, location: @location, machine: FactoryBot.create(:machine, id: 10, year: 2010, manufacturer: 'Williams', ic_eligible: true))

      visit '/portland/?by_location_id=' + @location.id.to_s
      page.find("div#machine_tools_lmx_banner_#{@lmx.id}").click

      expect(page).to have_css('.ic_unknown')
    end

    it 'allows user to toggle on flag' do
      @lmx = FactoryBot.create(:location_machine_xref, id: 11, location: @location, machine: FactoryBot.create(:machine, id: 10, year: 2010, manufacturer: 'Williams', ic_eligible: true))

      visit '/portland/?by_location_id=' + @location.id.to_s
      page.find("div#machine_tools_lmx_banner_#{@lmx.id}").click

      find('.ic_button').click

      sleep 0.5

      expect(page).to have_css('.ic_yes')

      user_submission = UserSubmission.last

      expect(user_submission.user_id).to eq(@user.id)
      expect(user_submission.machine_id).to eq(10)
      expect(user_submission.submission_type).to eq(UserSubmission::IC_TOGGLE_TYPE)
    end

    it 'allows user to toggle off flag' do
      @lmx = FactoryBot.create(:location_machine_xref, id: 11, location: @location, machine: FactoryBot.create(:machine, id: 10, year: 2010, manufacturer: 'Williams', ic_eligible: true))

      visit '/portland/?by_location_id=' + @location.id.to_s
      page.find("div#machine_tools_lmx_banner_#{@lmx.id}").click

      find('.ic_unknown').click
      find('.ic_yes').click

      sleep 1

      expect(page).to have_css('.ic_no')
    end
  end

  describe 'autocomplete', type: :feature, js: true do
    before(:each) do
      FactoryBot.create(:location_machine_xref, location: @location, machine: FactoryBot.create(:machine, year: 2010, manufacturer: 'Williams'))
    end

    it 'adds by machine name from input -- autocorrect picks via id' do
      @user = FactoryBot.create(:user)
      login(@user)

      FactoryBot.create(:machine, id: 10, name: 'Sassy Madness', year: 1980, manufacturer: 'Bally')
      FactoryBot.create(:machine, id: 11, name: 'Sassy Madness', year: 2010, manufacturer: 'Bally')

      visit "/#{@region.name}/?by_location_id=#{@location.id}"

      find("#add_machine_location_banner_#{@location.id}").click

      sleep(1)

      fill_in('add_machine_by_name_1', with: 'sassy')

      page.execute_script %{ $('#add_machine_by_name_1').trigger('focus') }
      page.execute_script %{ $('#add_machine_by_name_1').trigger('keydown') }

      expect(page).to have_xpath('//div[contains(text(), "Sassy Madness (Bally, 1980)")]')
      expect(page).to have_xpath('//div[contains(text(), "Sassy Madness (Bally, 2010)")]')

      find(:xpath, '//div[contains(text(), "Sassy Madness (Bally, 2010)")]').click

      click_on 'add'

      sleep(1)

      expect(@location.reload.machines.map { |m| m.name + '-' + m.year.to_s + '-' + m.manufacturer.to_s }.sort).to eq([ 'Sassy Madness-2010-Bally', 'Test Machine Name-2010-Williams' ])
    end

    it 'adds by machine name from input' do
      @user = FactoryBot.create(:user)
      login(@user)

      FactoryBot.create(:machine, name: 'Sassy Madness')
      FactoryBot.create(:machine, name: 'Sassy From The Black Lagoon')
      FactoryBot.create(:machine, name: 'Cleo Game')

      visit "/#{@region.name}/?by_location_id=#{@location.id}"

      find("#add_machine_location_banner_#{@location.id}").click

      sleep(1)

      fill_in('add_machine_by_name_1', with: 'sassy')

      page.execute_script %{ $('#add_machine_by_name_1').trigger('focus') }
      page.execute_script %{ $('#add_machine_by_name_1').trigger('keydown') }

      expect(page).to have_xpath('//div[contains(text(), "Sassy From The Black Lagoon")]')
      expect(page).to have_xpath('//div[contains(text(), "Sassy Madness")]')
      expect(page).to_not have_xpath('//div[contains(text(), "Cleo Game")]')
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

      expect(page).to have_selector(".ui-menu-item-wrapper", text: "Another Test Machine")
      expect(page).to have_selector(".ui-menu-item-wrapper", text: "Test Machine Name")
      expect(page).to_not have_selector(".ui-menu-item-wrapper", text: "Cleo")
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

      expect(page).to have_selector(".ui-menu-item-wrapper", text: "Cleo North (Portland, OR)")
      expect(page).to have_selector(".ui-menu-item-wrapper", text: "Cleo South (Vancouver, WA)")
      expect(page).to_not have_selector(".ui-menu-item-wrapper", text: "Cleo West")
      expect(page).to_not have_selector(".ui-menu-item-wrapper", text: "Sassy")
    end

    it 'searches by city name from input' do
      FactoryBot.create(:location, id: 122, region: @region, name: 'Cleo North', city: 'Portland', state: 'OR')
      FactoryBot.create(:location, id: 123, region: @region, name: 'Cleo South', city: 'Portland', state: 'ME')
      FactoryBot.create(:location, id: 124, region: @region, name: 'Sassy', city: 'San Diego', state: 'CA')

      visit '/map'

      fill_in('address', with: 'port')

      page.execute_script %{ $('#address').trigger('focus') }
      page.execute_script %{ $('#address').trigger('keydown') }

      expect(page).to have_xpath('//div[contains(text(), "Portland, OR")]')
      expect(page).to have_xpath('//div[contains(text(), "Portland, ME")]')
      expect(page).to_not have_xpath('//div[contains(text(), "San Diego, CA")]')
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

      expect(page).to have_xpath('//div[contains(text(), "Test[]Location")]')

      page.find('div#other_search_options button#machine_section_link').click

      fill_in('by_machine_name', with: 'test[')

      page.execute_script %{ $('#by_machine_name').trigger('focus') }
      page.execute_script %{ $('#by_machine_name').trigger('keydown') }

      expect(page).to have_xpath('//div[contains(text(), "Test[]Machine")]')
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

    it 'allows case insensitive searches of a region' do
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

      expect(page).to have_select('by_machine_id', with_options: [ 'Test Machine Name' ])
    end

    it 'automatically loads with machine detail visible on a single location search' do
      @user = FactoryBot.create(:user)
      login(@user)

      visit "/#{@region.name}"
      page.find('input#location_search_button').click

      expect(page).to have_content('Test Location Name')
      expect(page).to have_content('303 Southeast 3rd Avenue, Portland, OR 97214')
      expect(page).to have_content('Upload a picture')
      expect(page).to have_content('Add a machine')
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

      visit '/operators'

      select('Quarter Bean', from: 'by_operator_id')
      page.find('input#location_search_button').click

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
      expect(page).to have_content('(This operator does not receive machine comments)')

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

      expect(page).to have_select('by_operator_id', options: [ 'All', 'Quarter Bean' ])
    end

    it 'displays message about operator receiving machine comments' do
      l = FactoryBot.create(:location, id: 45, region: @region, name: 'Cleo', operator: FactoryBot.create(:operator, name: 'Quarter Bean', email: 'foo@bar.com', region: @region))

      visit "/#{@region.name}?by_location_id=#{l.reload.id}"

      expect(page).to have_content('(This operator receives machine comments)')
    end

    it 'displays location type for a location, if it is available' do
      FactoryBot.create(:location, id: 46, region: @region, name: 'Cleo', location_type: FactoryBot.create(:location_type, name: 'bar'))
      FactoryBot.create(:location, id: 47, region: @region, name: 'Bawb')

      visit "/#{@region.name}"

      page.find('input#location_search_button').click

      expect(page).to have_content("Cleo\nbar")
      expect(page).to have_content('Bawb')
    end

    it 'displays appropriate values in location description' do
      @user = FactoryBot.create(:user)
      login(@user)

      visit "/#{@region.name}"
      page.find('input#location_search_button').click

      page.find("#location_detail_location_#{@location.id} .meta_image").click
      fill_in("new_desc_#{@location.id}", with: 'New Condition')
      click_on 'Save'

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

    [ Region.find_by_name('portland'), nil ].each do |region|
      it 'honors direct link for location' do
        location = FactoryBot.create(:location, id: 111, region: region)

        visit "/#{region ? region.name : 'map'}/?by_location_id=#{location.id}"
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

    it 'has a machine dropdown with year and manufacturer if available' do
      FactoryBot.create(:location_machine_xref, location: FactoryBot.create(:location, id: 55, region: @region), machine: FactoryBot.create(:machine, name: 'foo', manufacturer: 'stern'))
      FactoryBot.create(:location_machine_xref, location: FactoryBot.create(:location, id: 56, region: @region), machine: FactoryBot.create(:machine, name: 'bar', year: 2000, manufacturer: 'bally'))
      FactoryBot.create(:location_machine_xref, location: FactoryBot.create(:location, id: 57, region: @region), machine: FactoryBot.create(:machine, name: 'baz', year: 2001))

      visit "/#{@region.name}"
      page.find('div#other_search_options button#machine_section_link').click

      expect(page).to have_select('by_machine_id', with_options: [ 'foo (stern)', 'bar (bally, 2000)', 'baz (2001)' ])
    end

    it 'has a location dropdown with city' do
      FactoryBot.create(:location, id: 11, region: @region, name: 'Cleo North', city: 'Portland', state: 'OR')

      visit "/#{@region.name}"
      page.find('div#other_search_options button#location_section_link').click

      expect(page).to have_select('by_location_id', with_options: [ 'Cleo North', '(Portland)' ])
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
  end
end
