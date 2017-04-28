require 'spec_helper'

describe LocationsController do
  before(:each) do
    login

    @region = FactoryGirl.create(:region, name: 'portland', full_name: 'portland', lat: 1, lon: 2, motd: 'This is a MOTD', n_search_no: 4, should_email_machine_removal: 1)
  end

  describe 'confirm location', type: :feature, js: true do
    before(:each) do
      @user = FactoryGirl.create(:user, username: 'ssw')
      page.set_rack_session('warden.user.user.key' => User.serialize_into_session(@user).unshift('User'))

      @location = FactoryGirl.create(:location, region_id: @region.id, name: 'Cleo')
      @machine = FactoryGirl.create(:machine, name: 'Bawb')
    end

    it 'lets you click a button to update the date_last_updated' do
      visit '/portland/?by_location_id=' + @location.id.to_s
      find("#confirm_location_#{@location.id} span.confirm_button").click

      sleep 1

      expect(@location.reload.date_last_updated).to eq(Date.today)
      expect(find("#last_updated_location_#{@location.id}")).to have_content("Location last updated: #{Time.now.strftime('%b-%d-%Y')} by ssw")
      expect(URI.parse(page.find_link('ssw')['href']).to_s).to match(%r{\/users\/#{@user.id}\/profile})
    end

    it 'displays no username when it was last updated by a non-user' do
      @location.date_last_updated = Date.today
      @location.save(validate: false)

      visit '/portland/?by_location_id=' + @location.id.to_s

      expect(find("#last_updated_location_#{@location.id}")).to have_content("Location last updated: #{Time.now.strftime('%b-%d-%Y')}")
    end
  end
  describe 'remove machine - not authed', type: :feature, js: true do
    before(:each) do
      @location = FactoryGirl.create(:location, region_id: @region.id, name: 'Cleo')
      @machine = FactoryGirl.create(:machine, name: 'Bawb')
    end

    it 'removes a machine from a location' do
      logout

      FactoryGirl.create(:location_machine_xref, location: @location, machine: @machine)

      @location.reload

      sleep 1

      visit '/portland/?by_location_id=' + @location.id.to_s

      sleep 1

      expect(page).to_not have_selector("input#remove_machine_#{LocationMachineXref.where(location_id: @location.id, machine_id: @machine.id).first.id}")
    end
  end

  describe 'remove machine', type: :feature, js: true do
    before(:each) do
      @user = FactoryGirl.create(:user, username: 'ssw', email: 'ssw@test.com')
      page.set_rack_session('warden.user.user.key' => User.serialize_into_session(@user).unshift('User'))

      @location = FactoryGirl.create(:location, region_id: @region.id, name: 'Cleo')
      @machine = FactoryGirl.create(:machine, name: 'Bawb')
    end

    def handle_js_confirm(accept = true)
      page.evaluate_script 'window.original_confirm_function = window.confirm'
      page.evaluate_script "window.confirm = function(msg) { return #{accept}; }"
      yield
    ensure
      page.evaluate_script 'window.confirm = window.original_confirm_function'
    end

    it 'removes a machine from a location' do
      FactoryGirl.create(:location_machine_xref, location: @location, machine: @machine)

      page.driver.headers = { 'User-Agent' => 'Mozilla/5.0 (cleOS)' }

      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          body: "Cleo\nBawb\nportland\n(user_id: #{@user.id}) (entered from 127.0.0.1 via Mozilla/5.0 (cleOS) by ssw (ssw@test.com))",
          subject: 'PBM - Someone removed a machine from a location',
          to: [],
          from: 'admin@pinballmap.com'
        )
      end

      visit '/portland/?by_location_id=' + @location.id.to_s

      handle_js_confirm do
        click_button 'remove'
      end

      sleep 1

      expect(LocationMachineXref.all).to eq([])
      expect(@location.reload.date_last_updated).to eq(Date.today)
      expect(find("#last_updated_location_#{@location.id}")).to have_content("Location last updated: #{Time.now.strftime('%b-%d-%Y')}")

      expect(UserSubmission.count).to eq(2)
      submission = UserSubmission.second
      expect(submission.submission_type).to eq(UserSubmission::REMOVE_MACHINE_TYPE)
      expect(submission.submission).to eq("Cleo (1)\nBawb (1)\nportland (1)")
      expect(submission.user_id).to eq(User.last.id)
    end

    it 'removes a machine from a location - allows you to cancel out of remove' do
      lmx = FactoryGirl.create(:location_machine_xref, location: @location, machine: @machine)

      expect(Pony).to_not receive(:mail)

      visit '/portland/?by_location_id=' + @location.id.to_s

      handle_js_confirm(false) do
        click_button 'remove'
      end

      sleep 1

      expect(LocationMachineXref.all).to eq([lmx])
    end
  end

  describe 'search locations', type: :feature, js: true do
    before(:each) do
    end

    it 'displays a location not found message instead of the ocean' do
      visit '/portland/?by_location_id=-1'

      expect(page).to have_content('NOT FOUND IN THIS REGION. PLEASE SEARCH AGAIN. Use the dropdown or the autocompleting textbox if you want results.')
    end
  end

  describe 'initial search by passed in param', type: :feature, js: true do
    before(:each) do
      @type = FactoryGirl.create(:location_type, name: 'Bar')
      @zone = FactoryGirl.create(:zone, region: @region, name: 'DT')
      @operator = FactoryGirl.create(:operator, region: @region, name: 'Quarterworld')
      @location = FactoryGirl.create(:location, region: @region, city: 'Portland', name: 'Cleo', zone: @zone, location_type: @type, operator: @operator)
      @machine = FactoryGirl.create(:machine, name: 'Barb', ipdb_id: 777)
      FactoryGirl.create(:location_machine_xref, location: @location, machine: @machine)

      FactoryGirl.create(:location, region: @region, name: 'Sass', city: 'Beaverton')
    end

    it 'by_city_id' do
      visit '/portland/?by_city_id=' + @location.city

      expect(page).to have_content('Cleo')
      expect(page).to_not have_content('Sass')
    end

    it 'by_operator_id' do
      visit '/portland/?by_operator_id=' + @location.operator_id.to_s

      expect(page).to have_content('Cleo')
      expect(page).to_not have_content('Sass')
    end

    it 'by_machine_group_id' do
      machine_group = FactoryGirl.create(:machine_group, id: 1001, name: 'Sass')
      sass_reg_ed = FactoryGirl.create(:machine, name: 'Sass Reg Ed', machine_group_id: 1001)
      sass_tourn_ed = FactoryGirl.create(:machine, name: 'Sass Tournament Ed', machine_group_id: 1001)
      machine_group_location = FactoryGirl.create(:location, region: @region)

      FactoryGirl.create(:location_machine_xref, location: machine_group_location, machine: sass_reg_ed)
      FactoryGirl.create(:location_machine_xref, location: machine_group_location, machine: sass_tourn_ed)

      visit '/portland/?by_machine_group_id=' + machine_group.id.to_s

      expect(page).to have_content('Sass Reg Ed')
      expect(page).to have_content('Sass Tournament Ed')
      expect(page).to_not have_content('Barb')
    end

    it 'by_location_id' do
      visit '/portland/?by_location_id=' + @location.id.to_s

      expect(page).to have_content('Cleo')
      expect(page).to_not have_content('Sass')
    end

    it 'by_location_id -- multiple ids' do
      other_location = FactoryGirl.create(:location, region: @region, name: 'Zelda')

      visit '/portland/?by_location_id=' + @location.id.to_s + '_' + other_location.id.to_s

      expect(page).to have_content('Cleo')
      expect(page).to have_content('Zelda')
      expect(page).to_not have_content('Sass')
    end

    it 'by_zone_id' do
      visit '/portland/?by_zone_id=' + @zone.id.to_s

      expect(page).to have_content('Cleo')
      expect(page).to_not have_content('Sass')
    end

    it 'by_zone_id -- multiple ids' do
      other_zone = FactoryGirl.create(:zone, name: 'NE')
      FactoryGirl.create(:location, region: @region, name: 'Zelda', zone: other_zone)
      visit '/portland/?by_zone_id=' + @zone.id.to_s + '_' + other_zone.id.to_s

      expect(page).to have_content('Cleo')
      expect(page).to have_content('Zelda')
      expect(page).to_not have_content('Sass')
    end

    it 'by_type_id' do
      visit '/portland/?by_location_type_id=' + @type.id.to_s

      expect(page).to have_content('Cleo')
      expect(page).to_not have_content('Sass')
    end

    it 'by_type_id -- multiple ids' do
      other_type = FactoryGirl.create(:location_type, name: 'PUB')
      FactoryGirl.create(:location, region: @region, name: 'Zelda', location_type: other_type)

      visit '/portland/?by_location_type_id=' + @type.id.to_s + '_' + other_type.id.to_s

      expect(page).to have_content('Cleo')
      expect(page).to have_content('Zelda')
      expect(page).to_not have_content('Sass')
    end

    it 'by_ipdb_id' do
      visit '/portland/?by_ipdb_id=' + @machine.ipdb_id.to_s

      expect(page).to have_content('Cleo')
      expect(page).to_not have_content('Sass')
    end

    it 'by_machine_id' do
      visit '/portland/?by_machine_id=' + @machine.id.to_s

      expect(page).to have_content('Cleo')
      expect(page).to_not have_content('Sass')
    end

    it 'by_machine_id -- multiple ids' do
      other_machine = FactoryGirl.create(:machine, name: 'Cool')
      other_location = FactoryGirl.create(:location, region: @region, name: 'Zelda')
      FactoryGirl.create(:location_machine_xref, location: other_location, machine: other_machine)

      visit '/portland/?by_machine_id=' + @machine.id.to_s + '_' + other_machine.id.to_s

      expect(page).to have_content('Cleo')
      expect(page).to have_content('Zelda')
      expect(page).to_not have_content('Sass')
    end
  end

  describe 'update_metadata', type: :feature, js: true do
    before(:each) do
      @user = FactoryGirl.create(:user)
      page.set_rack_session('warden.user.user.key' => User.serialize_into_session(@user).unshift('User'))

      @location = FactoryGirl.create(:location, region: @region, name: 'Cleo')
    end

    it 'does not save data if any formats are invalid - website and phone' do
      stub_const('ENV', 'RAKISMET_KEY' => 'asdf')

      expect(Rakismet).to receive(:akismet_call).twice.and_return('false')

      o = FactoryGirl.create(:operator, region: @location.region, name: 'Quarterworld')

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
      expect(page).to have_content('format invalid, please use ###-###-####')

      t = FactoryGirl.create(:location_type, name: 'Bar')

      visit '/portland/?by_location_id=' + @location.id.to_s

      find('.location_meta span.meta_image').click
      fill_in("new_phone_#{@location.id}", with: '555-555-5555')
      fill_in("new_website_#{@location.id}", with: 'www.foo.com')
      select('Bar', from: "new_location_type_#{@location.id}")
      click_on 'Save'

      sleep 1

      expect(@location.reload.location_type_id).to eq(t.id)
      expect(@location.phone).to eq('555-555-5555')
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
      t = FactoryGirl.create(:location_type, name: 'Bar')
      o = FactoryGirl.create(:operator, region: @location.region, name: 'Quarterworld')

      visit '/portland/?by_location_id=' + @location.id.to_s

      find('.location_meta span.meta_image').click
      fill_in("new_website_#{@location.id}", with: 'http://www.foo.com')
      fill_in("new_phone_#{@location.id}", with: '555-555-5555')
      select('Bar', from: "new_location_type_#{@location.id}")
      select('Quarterworld', from: "new_operator_#{@location.id}")
      click_on 'Save'

      sleep 1

      expect(@location.reload.website).to eq('http://www.foo.com')
      expect(@location.phone).to eq('555-555-5555')
      expect(@location.operator_id).to eq(o.id)
      expect(@location.location_type_id).to eq(t.id)
      expect(page).to_not have_css('div#flash_error')
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
      @user = FactoryGirl.create(:user)
      page.set_rack_session('warden.user.user.key' => User.serialize_into_session(@user).unshift('User'))

      @location = FactoryGirl.create(:location, region: @region, name: 'Cleo')
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
