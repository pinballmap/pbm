require 'spec_helper'

describe PagesController do
  before(:each) do
    @region = FactoryGirl.create(:region, name: 'portland', full_name: 'Portland')
    @location = FactoryGirl.create(:location, region: @region, state: 'OR')
  end

  describe 'Events', type: :feature, js: true do
    it 'handles basic event displaying' do
      FactoryGirl.create(:event, region: @region, location: @location, name: 'event 1', start_date: Date.today)
      FactoryGirl.create(:event, region: @region, location: @location, name: 'event 2', start_date: Date.today + 1)
      FactoryGirl.create(:event, region: @region, location: @location, name: 'event 3', start_date: Date.today - 1)
      FactoryGirl.create(:event, region: @region, location: @location, name: 'event 4')
      FactoryGirl.create(:event, region: @region, location: @location, external_location_name: 'External location', name: 'event 5')
      FactoryGirl.create(:event, region: @region, external_location_name: 'External location', name: 'event 6')

      visit '/portland/events'

      expect(page).to have_content('event 6 @ External location')
      expect(page).to have_content('event 5 @ Test Location Name')
      expect(page).to have_content("event 4 @ Test Location Name #{Date.today - 1}")
      expect(page).to have_content("event 3 @ Test Location Name #{Date.today}")
      expect(page).to have_content("event 1 @ Test Location Name #{Date.today + 1}")
      expect(page).to have_content('event 2 @ Test Location Name')
    end

    it 'is case insensitive for region name' do
      chicago_region = FactoryGirl.create(:region, name: 'chicago', full_name: 'Chicago')
      FactoryGirl.create(:event, region: chicago_region, name: 'event 1')

      visit '/CHICAGO/events'

      expect(page).to have_content('event 1')
    end

    it 'does not display events that are a week older than their end date' do
      FactoryGirl.create(:event, region: @region, location: @location, name: 'event 1', start_date: Date.today, end_date: Date.today)
      FactoryGirl.create(:event, region: @region, location: @location, name: 'event 2', start_date: Date.today - 8, end_date: Date.today - 8)

      visit '/portland/events'

      expect(page).to have_content('event 1')
      expect(page).to_not have_content('event 2')
    end

    it 'does not display events that are a week older than start date if there is no end date' do
      FactoryGirl.create(:event, region: @region, location: @location, name: 'event 1', start_date: Date.today)
      FactoryGirl.create(:event, region: @region, location: @location, name: 'event 2', start_date: Date.today - 8)

      visit '/portland/events'

      expect(page).to have_content('event 1')
      expect(page).to_not have_content('event 2')
    end
  end

  describe 'High roller list', type: :feature, js: true do
    it 'should have intro text that displays correct number of locations and machines for a region' do
      chicago_region = FactoryGirl.create(:region, name: 'chicago')
      portland_location = FactoryGirl.create(:location, region: @region)
      chicago_location = FactoryGirl.create(:location, region: chicago_region)

      machine = FactoryGirl.create(:machine)

      portland_lmx = FactoryGirl.create(:location_machine_xref, location: @location, machine: machine)
      another_portland_lmx = FactoryGirl.create(:location_machine_xref, location: portland_location, machine: machine)
      FactoryGirl.create(:location_machine_xref, location: chicago_location, machine: machine)

      FactoryGirl.create(:machine_score_xref, location_machine_xref: portland_lmx, score: 100, initials: 'ssw', rank: 1)
      FactoryGirl.create(:machine_score_xref, location_machine_xref: portland_lmx, score: 90, initials: 'rtgt', rank: 2)
      FactoryGirl.create(:machine_score_xref, location_machine_xref: another_portland_lmx, score: 200, initials: 'ssw', rank: 1)

      visit '/portland/high_rollers'

      expect(page).to have_content('ssw: with 2 scores')
      expect(page).to have_content('rtgt: with 1 scores')
    end
  end

  describe 'Top 10 Machine Counts', type: :feature, js: true do
    it 'shows the top 10 machine counts on the about page' do
      11.times do |machine_name_counter|
        machine_name_counter.times do
          FactoryGirl.create(:location_machine_xref, location: @location, machine: Machine.where(name: "Machine#{machine_name_counter}").first_or_create)
        end
      end

      visit '/portland/about'

      expect(page).to have_content('Machine10: with 10 machines Machine9: with 9 machines Machine8: with 8 machines Machine7: with 7 machines Machine6: with 6 machines Machine5: with 5 machines Machine4: with 4 machines Machine3: with 3 machines Machine2: with 2 machines Machine1: with 1 machines')
    end
  end

  describe 'Links', type: :feature, js: true do
    it 'shows links in a region' do
      chicago = FactoryGirl.create(:region, name: 'chicago', full_name: 'Chicago')

      FactoryGirl.create(:region_link_xref, region: @region, description: 'foo')
      FactoryGirl.create(:region_link_xref, region: chicago, name: 'chicago link 1', category: 'main links', sort_order: 2, description: 'desc1')
      FactoryGirl.create(:region_link_xref, region: chicago, name: 'cool link 1', category: 'cool links', sort_order: 1, description: 'desc2')

      visit '/chicago/about'

      expect(page).to have_content('cool links cool link 1 desc2 main links chicago link 1 desc1')
    end

    it 'sort order does not cause headers to display twice' do
      FactoryGirl.create(:region_link_xref, region: @region, description: 'desc', name: 'link 1', category: 'main links', sort_order: 2)
      FactoryGirl.create(:region_link_xref, region: @region, description: 'desc', name: 'link 2', category: 'main links', sort_order: 1)
      FactoryGirl.create(:region_link_xref, region: @region, description: 'desc', name: 'link 3', category: 'other category')

      visit "/#{@region.name}/about"

      expect(page).to have_content('main links link 2 desc link 1 desc other category link 3 desc')
    end
  end

  describe 'Location suggestions', type: :feature, js: true do
    it 'limits state dropdown to unique states within a region' do
      chicago = FactoryGirl.create(:region, name: 'chicago')

      FactoryGirl.create(:location, region: @region, state: 'WA')
      FactoryGirl.create(:location, region: chicago, state: 'IL')

      visit "/#{@region.name}/suggest"

      expect(page).to have_select('location_state', options: %w(OR WA))
    end
  end

  describe 'Homepage', type: :feature, js: true do
    it 'shows the proper number of locations and machines per region' do
      chicago = FactoryGirl.create(:region, name: 'chicago', full_name: 'Chicago')
      machine = FactoryGirl.create(:machine)

      FactoryGirl.create(:location_machine_xref, location: @location, machine: machine)
      FactoryGirl.create(:location_machine_xref, location: FactoryGirl.create(:location, region: @region), machine: machine)

      FactoryGirl.create(:location_machine_xref, location: FactoryGirl.create(:location, region: chicago), machine: machine)

      visit '/'

      expect(page).to have_css('div#map_summaries')
      expect(page).to have_content('Chicago Tracking: 1 Locations 1 Machines Portland Tracking: 2 Locations 2 Machines')
    end

    it 'shows the proper page title' do

      visit '/'

      expect(page).to have_title('Pinball Map')
      expect(page).not_to have_title('Apps')
    end
  end

  describe 'Apps pages', type: :feature, js: true do
    it 'shows the proper page title' do

      visit '/apps'
      expect(page).to have_title('Apps')

      visit '/apps/support'
      expect(page).to have_title('Apps')
    end
  end

  describe 'Landing page for a region', type: :feature, js: true do
    it 'shows the proper location and machine counts in the intro text' do
      chicago = FactoryGirl.create(:region, name: 'chicago')
      machine = FactoryGirl.create(:machine)

      FactoryGirl.create(:location_machine_xref, location: @location, machine: machine)
      FactoryGirl.create(:location_machine_xref, location: FactoryGirl.create(:location, region: @region), machine: machine)

      FactoryGirl.create(:location_machine_xref, location: FactoryGirl.create(:location, region: chicago), machine: machine)

      visit '/portland'

      expect(page).to have_content('2 locations and 2 machines')
    end

    it 'does not show high scores when none exist' do
      visit '/portland'

      expect(page).to_not have_selector('#ticker')
    end

    it 'shows high scores when they exist' do
      lmx = FactoryGirl.create(:location_machine_xref, location: @location, machine: FactoryGirl.create(:machine))
      FactoryGirl.create(:machine_score_xref, location_machine_xref: lmx, initials: 'cap', score: 1234, rank: 1)

      visit '/portland'

      expect(page).to have_content("Test Location Name's Test Machine Name: GC with 1,234 by cap")
    end

    it 'shows the proper page title' do

      visit '/portland'

      expect(page).to have_title('Portland Pinball Map')
      expect(page).not_to have_title('Apps')
    end
  end
end
