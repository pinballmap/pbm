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

      expect(page).to_not have_selector("div#high_score_lmx_#{lmx.id}")
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
      page.find("div#high_score_lmx_#{lmx.id}").click
      fill_in('score', with: 1234)
      click_on('Save')

      sleep(1)

      expect(lmx.machine_score_xrefs.first.score).to eq(1234)
      expect(lmx.machine_score_xrefs.first.username).to eq('cap')
    end

    it 'removes non-digit characters from high scores' do
      lmx = FactoryBot.create(:location_machine_xref, id: 1, location: @location, machine: FactoryBot.create(:machine))

      visit "/#{@region.name}/?by_location_id=#{@location.id}"

      page.find("div#machine_tools_lmx_banner_#{lmx.id}").click
      page.find("div#high_score_lmx_#{lmx.id}").click
      fill_in('score', with: '1,234')
      click_on('Save')

      sleep(1)

      expect(lmx.machine_score_xrefs.first.score).to eq(1234)
      expect(lmx.machine_score_xrefs.first.username).to eq('cap')
    end

    it 'ignores non-numeric scores' do
      lmx = FactoryBot.create(:location_machine_xref, location: @location, machine: FactoryBot.create(:machine))

      visit "/#{@region.name}/?by_location_id=#{@location.id}"

      page.find("div#machine_tools_lmx_banner_#{lmx.id}").click
      page.find("div#high_score_lmx_#{lmx.id}").click
      fill_in('score', with: 'fword')
      click_on('Save')

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

      FactoryBot.create(:user_submission, created_at: '2025-01-01', region: @region, location: @location, location_name: @location.name, user_name: 'ssw', city_name: 'Portland', machine_name: region_machine.name, submission_type: UserSubmission::NEW_SCORE_TYPE)

      FactoryBot.create(:user_submission, created_at: '2025-01-01', region: chicago, location: chicago_location, location_name: chicago_location.name, user_name: 'ssw', city_name: 'Chicago', machine_name: out_of_region_machine.name, submission_type: UserSubmission::NEW_SCORE_TYPE)

      visit "/#{@region.name}/machine_score_xrefs.rss"

      expect(page.body).to have_content('Spider-Man')
      expect(page.body).to_not have_content('Twilight Zone')
    end

    it 'Should only display the last 50 scores in the feed' do
      old_machine = FactoryBot.create(:machine, name: 'Spider-Man')
      recent_machine = FactoryBot.create(:machine, name: 'Twilight Zone')

      50.times do
        FactoryBot.create(:user_submission, created_at: '2025-01-01', region: @region, location: @location, location_name: @location.name, user_name: 'ssw', city_name: 'Portland', machine_name: old_machine.name, submission_type: UserSubmission::NEW_SCORE_TYPE)
      end
      50.times do
        FactoryBot.create(:user_submission, created_at: '2025-06-01', region: @region, location: @location, location_name: @location.name, user_name: 'ssw', city_name: 'Portland', machine_name: recent_machine.name, submission_type: UserSubmission::NEW_SCORE_TYPE)
      end
      FactoryBot.create(:user_submission, created_at: '2025-07-01', region: @region, location: @location, location_name: @location.name, user_name: 'ssw', city_name: 'Portland', machine_name: 'Argh', submission_type: UserSubmission::NEW_SCORE_TYPE, deleted_at: '2025-06-15')

      visit "/#{@region.name}/machine_score_xrefs.rss"

      expect(page.body).to have_content('Twilight Zone')
      expect(page.body).to_not have_content('Spider-Man')
      expect(page.body).to_not have_content('Argh')
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

      page.find("div#high_score_lmx_#{lmx.id}").click
      fill_in('score', with: 1234)
      click_on('Save')

      sleep(1)

      expect(URI.parse(page.find_link('cap')['href']).to_s).to match(%r{/users/#{@user.username}/profile})
    end
  end

  describe 'edit or delete scores', type: :feature, js: true do
    before(:each) do
      @lmx = FactoryBot.create(:location_machine_xref, location: @location, machine: FactoryBot.create(:machine))
      @user = FactoryBot.create(:user, id: 11, username: 'ssw', email: 'foo@bar.com')

      login(@user)
    end

    it 'allows you to delete a high score if you were the one that entered it' do
      FactoryBot.create(:machine_score_xref, location_machine_xref: @lmx, score: 100, user: @user, id: 55)
      FactoryBot.create(:user_submission, created_at: '2025-01-01', region: @region, location: @location, location_name: @location.name, user_id: @user.id, city_name: 'Portland', machine_name: 'Machine', submission_type: UserSubmission::NEW_SCORE_TYPE, machine_score_xref_id: 55)

      visit '/map/?by_location_id=' + @lmx.location.id.to_s
      page.find("div#machine_tools_lmx_banner_#{@lmx.id}").click

      expect(page).to have_selector("input[type=submit][value='delete']")

      page.accept_confirm do
        click_button 'delete'
      end

      sleep 1

      @lmx.reload
      expect(@lmx.machine_score_xrefs.size).to eq(0)
    end

    it 'will not allow you to delete a high score if you were not the one that entered it' do
      FactoryBot.create(:machine_score_xref, location_machine_xref: @lmx, score: 100, user: nil)

      visit '/map/?by_location_id=' + @lmx.location.id.to_s
      page.find("div#machine_tools_lmx_banner_#{@lmx.id}").click

      expect(page).to_not have_selector("input[type=submit][value='delete']")
    end

    it 'allows you to update a high score if you were the one that entered it' do
      FactoryBot.create(:machine_score_xref, location_machine_xref: @lmx, score: 100, user: @user, id: 55)
      FactoryBot.create(:user_submission, created_at: '2025-01-01', region: @region, location: @location, location_name: @location.name, user_id: @user.id, city_name: 'Portland', machine_name: 'Machine', submission_type: UserSubmission::NEW_SCORE_TYPE, machine_score_xref_id: 55)

      visit '/map/?by_location_id=' + @lmx.location.id.to_s
      page.find("div#machine_tools_lmx_banner_#{@lmx.id}").click

      find('a#edit_high_score_' + @lmx.machine_score_xrefs.first.id.to_s + '.button').click
      fill_in 'score', with: 200

      page.accept_confirm do
        click_button 'Update Score'
      end

      sleep 1

      @lmx.reload
      expect(@lmx.machine_score_xrefs.first.score).to eq(200)
    end

    it 'will not allow you to update a high score if you were not the one that entered it' do
      FactoryBot.create(:machine_score_xref, location_machine_xref: @lmx, score: 100, user: nil)

      visit '/map/?by_location_id=' + @lmx.location.id.to_s
      page.find("div#machine_tools_lmx_banner_#{@lmx.id}").click

      expect(page).to_not have_selector('a#edit_high_score_' + @lmx.machine_score_xrefs.first.id.to_s + '.button')
    end

    it 'will only allow you to update a high score with numerals' do
      FactoryBot.create(:machine_score_xref, location_machine_xref: @lmx, score: 100, user: @user)

      visit '/map/?by_location_id=' + @lmx.location.id.to_s
      page.find("div#machine_tools_lmx_banner_#{@lmx.id}").click

      find('a#edit_high_score_' + @lmx.machine_score_xrefs.first.id.to_s + '.button').click
      fill_in 'score', with: 'words'

      page.accept_confirm do
        click_button 'Update Score'
      end

      sleep 1

      @lmx.reload
      expect(@lmx.machine_score_xrefs.first.score).to eq(100)

      find('a#edit_high_score_' + @lmx.machine_score_xrefs.first.id.to_s + '.button').click
      fill_in 'score', with: 0

      page.accept_confirm do
        click_button 'Update Score'
      end

      sleep 1

      @lmx.reload
      expect(@lmx.machine_score_xrefs.first.score).to eq(100)

      find('a#edit_high_score_' + @lmx.machine_score_xrefs.first.id.to_s + '.button').click
      fill_in 'score', with: ''

      page.accept_confirm do
        click_button 'Update Score'
      end

      sleep 1

      @lmx.reload
      expect(@lmx.machine_score_xrefs.first.score).to eq(100)
    end
  end
end
