require 'spec_helper'

describe PagesController do
  before(:each) do
    @region = FactoryGirl.create(:region, :name => 'portland')
    @location = FactoryGirl.create(:location, :region => @region, :state => 'OR')
  end

  describe 'Events', :type => :feature, :js => true do
    it 'handles basic event displaying' do
      FactoryGirl.create(:event, :region => @region, :location => @location, :name => 'event 1', :start_date => Date.today)
      FactoryGirl.create(:event, :region => @region, :location => @location, :name => 'event 2', :start_date => Date.today + 1)
      FactoryGirl.create(:event, :region => @region, :location => @location, :name => 'event 3', :start_date => Date.today - 1)
      FactoryGirl.create(:event, :region => @region, :location => @location, :name => 'event 4')
      FactoryGirl.create(:event, :region => @region, :location => @location, :external_location_name => 'External location', :name => 'event 5')
      FactoryGirl.create(:event, :region => @region, :external_location_name => 'External location', :name => 'event 6')

      visit '/portland/events'

      page.should have_content('event 6 @ External location')
      page.should have_content('event 5 @ Test Location Name')
      page.should have_content("event 4 @ Test Location Name #{Date.today - 1}")
      page.should have_content("event 3 @ Test Location Name #{Date.today}")
      page.should have_content("event 1 @ Test Location Name #{Date.today + 1}")
      page.should have_content('event 2 @ Test Location Name')
    end

    it 'is case insensitive for region name' do
      chicago_region = FactoryGirl.create(:region, :name => 'chicago')
      FactoryGirl.create(:event, :region => chicago_region, :name => 'event 1')

      visit '/CHICAGO/events'

      page.should have_content('event 1')
    end

    it 'does not display events that are a week older than their end date' do
      FactoryGirl.create(:event, :region => @region, :location => @location, :name => 'event 1', :start_date => Date.today, :end_date => Date.today)
      FactoryGirl.create(:event, :region => @region, :location => @location, :name => 'event 2', :start_date => Date.today - 8, :end_date => Date.today - 8)

      visit '/portland/events'

      page.should have_content('event 1')
      page.should_not have_content('event 2')
    end

    it 'does not display events that are a week older than start date if there is no end date' do
      FactoryGirl.create(:event, :region => @region, :location => @location, :name => 'event 1', :start_date => Date.today)
      FactoryGirl.create(:event, :region => @region, :location => @location, :name => 'event 2', :start_date => Date.today - 8)

      visit '/portland/events'

      page.should have_content('event 1')
      page.should_not have_content('event 2')
    end
  end

  describe 'High roller list', :type => :feature, :js => true do
    it 'should have intro text that displays correct number of locations and machines for a region' do
      chicago_region = FactoryGirl.create(:region, :name => 'chicago')
      portland_location = FactoryGirl.create(:location, :region => @region)
      chicago_location = FactoryGirl.create(:location, :region => chicago_region)

      machine = FactoryGirl.create(:machine)

      portland_lmx = FactoryGirl.create(:location_machine_xref, :location => @location, :machine => machine)
      another_portland_lmx = FactoryGirl.create(:location_machine_xref, :location => portland_location, :machine => machine)
      FactoryGirl.create(:location_machine_xref, :location => chicago_location, :machine => machine)

      FactoryGirl.create(:machine_score_xref, :location_machine_xref => portland_lmx, :score => 100, :initials => 'ssw', :rank => 1)
      FactoryGirl.create(:machine_score_xref, :location_machine_xref => portland_lmx, :score => 90, :initials => 'rtgt', :rank => 2)
      FactoryGirl.create(:machine_score_xref, :location_machine_xref => another_portland_lmx, :score => 200, :initials => 'ssw', :rank => 1)

      visit '/portland/high_rollers'

      page.should have_content('ssw: with 2 scores')
      page.should have_content('rtgt: with 1 scores')
    end
  end

  describe 'Links', :type => :feature, :js => true do
    it 'shows links in a region' do
      chicago = FactoryGirl.create(:region, :name => 'chicago')

      FactoryGirl.create(:region_link_xref, :region => @region, :description => 'foo')
      FactoryGirl.create(:region_link_xref, :region => chicago, :name => 'chicago link 1', :category => 'main links', :sort_order => 2, :description => 'desc1')
      FactoryGirl.create(:region_link_xref, :region => chicago, :name => 'cool link 1', :category => 'cool links', :sort_order => 1, :description => 'desc2')

      visit '/chicago/about'

      page.should have_content('cool links cool link 1 desc2 main links chicago link 1 desc1')
    end

    it 'sort order does not cause headers to display twice' do
      FactoryGirl.create(:region_link_xref, :region => @region, :description => 'desc', :name => 'link 1', :category => 'main links', :sort_order => 2)
      FactoryGirl.create(:region_link_xref, :region => @region, :description => 'desc', :name => 'link 2', :category => 'main links', :sort_order => 1)
      FactoryGirl.create(:region_link_xref, :region => @region, :description => 'desc', :name => 'link 3', :category => 'other category')

      visit "/#{@region.name}/about"

      page.should have_content('main links link 2 desc link 1 desc other category link 3 desc')
    end
  end

  describe 'Location suggestions', :type => :feature, :js => true do
    it 'limits state dropdown to unique states within a region' do
      chicago = FactoryGirl.create(:region, :name => 'chicago')

      FactoryGirl.create(:location, :region => @region, :state => 'WA')
      FactoryGirl.create(:location, :region => chicago, :state => 'IL')

      visit "/#{@region.name}/suggest"

      page.should have_select('location_state', :options => ['OR', 'WA'])
    end
  end

  describe 'Homepage', :type => :feature, :js => true do
    it 'shows the proper number of locations and machines per region' do
      chicago = FactoryGirl.create(:region, :name => 'chicago')
      machine = FactoryGirl.create(:machine)

      FactoryGirl.create(:location_machine_xref, :location => @location, :machine => machine)
      FactoryGirl.create(:location_machine_xref, :location => FactoryGirl.create(:location, :region => @region), :machine => machine)

      FactoryGirl.create(:location_machine_xref, :location => FactoryGirl.create(:location, :region => chicago), :machine => machine)

      visit "/"

      page.should have_css('div#map_summaries')
      page.should have_content('Tracking: 2 Locations 2 Machines Tracking: 1 Locations 1 Machines')
    end
  end

  describe 'Landing page for a region', :type => :feature, :js => true do
    it 'shows the proper location and machine counts in the intro text' do
      chicago = FactoryGirl.create(:region, :name => 'chicago')
      machine = FactoryGirl.create(:machine)

      FactoryGirl.create(:location_machine_xref, :location => @location, :machine => machine)
      FactoryGirl.create(:location_machine_xref, :location => FactoryGirl.create(:location, :region => @region), :machine => machine)

      FactoryGirl.create(:location_machine_xref, :location => FactoryGirl.create(:location, :region => chicago), :machine => machine)

      visit "/portland"

      page.should have_content('2 locations and 2 machines')
    end

    it 'does not show high scores when none exist' do
      visit "/portland"

      page.should_not have_selector("#ticker")
    end

    it 'shows high scores when they exist' do
      lmx = FactoryGirl.create(:location_machine_xref, :location => @location, :machine => FactoryGirl.create(:machine))
      FactoryGirl.create(:machine_score_xref, :location_machine_xref => lmx, :initials => 'cap', :score => 1234, :rank => 1)

      visit "/portland"

      page.should have_content("Test Location Name's Test Machine Name: GC with 1,234 by cap")
    end
  end
end
