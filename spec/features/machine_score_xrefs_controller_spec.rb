require 'spec_helper'

describe MachineScoreXrefsController do
  before(:each) do
    @region = FactoryGirl.create(:region, name: 'portland', full_name: 'Portland')
    @location = FactoryGirl.create(:location, region: @region)
  end

  describe 'add machine scores - no auth', type: :feature, js: true do
    it 'does not allow you to enter a score if you are not logged in' do
      lmx = FactoryGirl.create(:location_machine_xref, location: @location, machine: FactoryGirl.create(:machine))

      visit "/#{@region.name}/?by_location_id=#{@location.id}"

      expect(page).to_not have_selector("div#add_scores_lmx_banner_#{lmx.id}")
    end
  end

  describe 'add machine scores', type: :feature, js: true do
    before(:each) do
      @user = FactoryGirl.create(:user, username: 'cap')
      page.set_rack_session('warden.user.user.key' => User.serialize_into_session(@user).unshift('User'))
    end

    it 'adds a score' do
      lmx = FactoryGirl.create(:location_machine_xref, location: @location, machine: FactoryGirl.create(:machine))

      visit "/#{@region.name}/?by_location_id=#{@location.id}"

      page.find("div#add_scores_lmx_banner_#{lmx.id}").click
      fill_in('score', with: 1234)
      select('GC', from: 'rank')
      click_on('Add Score')

      sleep(1)

      expect(lmx.machine_score_xrefs.first.score).to eq(1234)
      expect(lmx.machine_score_xrefs.first.username).to eq('cap')
      expect(lmx.machine_score_xrefs.first.rank).to eq(1)
    end

    it 'removes non-digit characters from high scores' do
      lmx = FactoryGirl.create(:location_machine_xref, id: 1, location: @location, machine: FactoryGirl.create(:machine))

      visit "/#{@region.name}/?by_location_id=#{@location.id}"

      page.find("div#add_scores_lmx_banner_#{lmx.id}").click
      fill_in('score', with: '1,234')
      select('GC', from: 'rank')
      click_on('Add Score')

      sleep(1)

      expect(lmx.machine_score_xrefs.first.score).to eq(1234)
      expect(lmx.machine_score_xrefs.first.username).to eq('cap')
      expect(lmx.machine_score_xrefs.first.rank).to eq(1)
    end
  end

  describe 'feeds', type: :feature, js: true do
    it 'Should only display scores from the region in scope' do
      region_machine = FactoryGirl.create(:machine, name: 'Spider-Man')
      out_of_region_machine = FactoryGirl.create(:machine, name: 'Twilight Zone')

      chicago = FactoryGirl.create(:region, name: 'Chicago')
      chicago_location = FactoryGirl.create(:location, name: 'Chicago Location', region: chicago)

      FactoryGirl.create(:machine_score_xref, location_machine_xref: FactoryGirl.create(:location_machine_xref, location: @location, machine: region_machine))
      FactoryGirl.create(:machine_score_xref, location_machine_xref: FactoryGirl.create(:location_machine_xref, location: chicago_location, machine: out_of_region_machine))

      visit "/#{@region.name}/machine_score_xrefs.rss"

      expect(page.body).to have_content('Spider-Man')
      expect(page.body).to_not have_content('Twilight Zone')
    end

    it 'Should only display the last 50 scores in the feed' do
      old_machine = FactoryGirl.create(:machine, name: 'Spider-Man')
      recent_machine = FactoryGirl.create(:machine, name: 'Twilight Zone')

      FactoryGirl.create(:location_machine_xref, id: 1, location: @location, machine: old_machine)
      (1 .. 50).each { |i| FactoryGirl.create(:location_machine_xref, id: i + 1, location: @location, machine: recent_machine) }
      (1 .. 50).each { |i| FactoryGirl.create(:machine_score_xref, location_machine_xref: LocationMachineXref.find(i + 1)) }

      visit "/#{@region.name}/machine_score_xrefs.rss"

      expect(page.body).to have_content('Twilight Zone')
      expect(page.body).to_not have_content('Spider-Man')
    end
  end

  describe 'displays scores correctly', type: :feature, js: true do
    it 'honors the hide/show of the display area' do
      @user = FactoryGirl.create(:user, username: 'cap')
      page.set_rack_session('warden.user.user.key' => User.serialize_into_session(@user).unshift('User'))

      lmx = FactoryGirl.create(:location_machine_xref, location: @location, machine: FactoryGirl.create(:machine))

      visit "/#{@region.name}/?by_location_id=#{@location.id}"

      expect(page).to_not have_css("div#show_scores_lmx_banner_#{lmx.id}")

      page.find("div#add_scores_lmx_banner_#{lmx.id}").click
      fill_in('score', with: 1234)
      select('GC', from: 'rank')
      click_on('Add Score')

      sleep(1)

      expect(page).to have_css("div#show_scores_lmx_banner_#{lmx.id}")
    end
  end
end
