require 'spec_helper'

describe MachineScoreXrefsController do
  before(:each) do
    @region = FactoryBot.create(:region, name: 'portland', full_name: 'Portland')
    @location = FactoryBot.create(:location, region: @region)
  end

  describe 'add machine scores - no auth', type: :feature, js: true do
    it 'does not allow you to enter a score if you are not logged in' do
      lmx = FactoryBot.create(:location_machine_xref, location: @location, machine: FactoryBot.create(:machine))
      @location.reload

      visit "/#{@region.name}/?by_location_id=#{@location.id}"

      sleep 1

      expect(page).to_not have_selector("div#add_scores_lmx_banner_#{lmx.id}")
    end
  end

  describe 'add machine scores', type: :feature, js: true do
    before(:each) do
      @user = FactoryBot.create(:user, username: 'cap')
      login(@user)
    end

    it 'adds a score' do
      lmx = FactoryBot.create(:location_machine_xref, location: @location, machine: FactoryBot.create(:machine))

      visit "/#{@region.name}/?by_location_id=#{@location.id}"

      page.find("div#machine_tools_lmx_banner_#{lmx.id}").click
      page.find("div#add_scores_lmx_banner_#{lmx.id}").click
      fill_in('score', with: 1234)
      click_on('Add Score')

      sleep(1)

      expect(lmx.machine_score_xrefs.first.score).to eq(1234)
      expect(lmx.machine_score_xrefs.first.username).to eq('cap')
    end

    it 'removes non-digit characters from high scores' do
      lmx = FactoryBot.create(:location_machine_xref, id: 1, location: @location, machine: FactoryBot.create(:machine))

      visit "/#{@region.name}/?by_location_id=#{@location.id}"

      page.find("div#machine_tools_lmx_banner_#{lmx.id}").click
      page.find("div#add_scores_lmx_banner_#{lmx.id}").click
      fill_in('score', with: '1,234')
      click_on('Add Score')

      sleep(1)

      expect(lmx.machine_score_xrefs.first.score).to eq(1234)
      expect(lmx.machine_score_xrefs.first.username).to eq('cap')
    end

    it 'ignores non-numeric scores' do
      lmx = FactoryBot.create(:location_machine_xref, location: @location, machine: FactoryBot.create(:machine))

      visit "/#{@region.name}/?by_location_id=#{@location.id}"

      page.find("div#machine_tools_lmx_banner_#{lmx.id}").click
      page.find("div#add_scores_lmx_banner_#{lmx.id}").click
      fill_in('score', with: 'fword')
      click_on('Add Score')

      sleep(1)

      expect(lmx.machine_score_xrefs.size).to eq(0)
    end
  end

  describe 'feeds', type: :feature, js: true do
    it 'Should only display scores from the region in scope' do
      region_machine = FactoryBot.create(:machine, name: 'Spider-Man')
      out_of_region_machine = FactoryBot.create(:machine, name: 'Twilight Zone')

      chicago = FactoryBot.create(:region, name: 'Chicago')
      chicago_location = FactoryBot.create(:location, name: 'Chicago Location', region: chicago)

      FactoryBot.create(:machine_score_xref, location_machine_xref: FactoryBot.create(:location_machine_xref, location: @location, machine: region_machine))
      FactoryBot.create(:machine_score_xref, location_machine_xref: FactoryBot.create(:location_machine_xref, location: chicago_location, machine: out_of_region_machine))

      visit "/#{@region.name}/machine_score_xrefs.rss"

      expect(page.body).to have_content('Spider-Man')
      expect(page.body).to_not have_content('Twilight Zone')
    end

    it 'Should only display the last 50 scores in the feed' do
      old_machine = FactoryBot.create(:machine, name: 'Spider-Man')
      recent_machine = FactoryBot.create(:machine, name: 'Twilight Zone')

      FactoryBot.create(:location_machine_xref, id: 1, location: @location, machine: old_machine)
      (1..50).each { |i| FactoryBot.create(:location_machine_xref, id: i + 1, location: @location, machine: recent_machine) }
      (1..50).each { |i| FactoryBot.create(:machine_score_xref, location_machine_xref: LocationMachineXref.find(i + 1)) }

      visit "/#{@region.name}/machine_score_xrefs.rss"

      expect(page.body).to have_content('Twilight Zone')
      expect(page.body).to_not have_content('Spider-Man')
    end
  end

  describe 'displays scores correctly', type: :feature, js: true do
    it 'honors the hide/show of the display area' do
      @user = FactoryBot.create(:user, username: 'cap')
      login(@user)

      lmx = FactoryBot.create(:location_machine_xref, location: @location, machine: FactoryBot.create(:machine))

      visit "/#{@region.name}/?by_location_id=#{@location.id}"
      page.find("div#machine_tools_lmx_banner_#{lmx.id}").click

      expect(page).to_not have_css('div.high_score_new_line')

      page.find("div#add_scores_lmx_banner_#{lmx.id}").click
      fill_in('score', with: 1234)
      click_on('Add Score')

      sleep(1)

      expect(page).to have_css("div#show_scores_lmx_#{lmx.id}")

      page.find("div#show_scores_lmx_#{lmx.id}").click

      sleep(1)

      expect(URI.parse(page.find_link('cap')['href']).to_s).to match(%r{/users/#{@user.username}/profile})
    end
  end
end
