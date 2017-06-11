require 'spec_helper'

describe Region do
  before(:each) do
    @region = FactoryGirl.create(:region, name: 'portland', full_name: 'Portland', should_auto_delete_empty_locations: 1)
    @other_region = FactoryGirl.create(:region, name: 'chicago')
  end

  describe '#delete_all_empty_locations' do
    it 'should remove all empty locations if the region has opted in to this functionality' do
      FactoryGirl.create(:location, region: @region)
      not_empty = FactoryGirl.create(:location, region: @region, name: 'not empty')
      FactoryGirl.create(:location_machine_xref, location: not_empty, machine: FactoryGirl.create(:machine))

      @region.delete_all_empty_locations

      expect(Location.all.count).to eq(1)
      expect(Location.first.name).to eq('not empty')
    end

    it 'should not remove all empty locations if the region has opted in to this functionality' do
      FactoryGirl.create(:location, region: @other_region, name: 'empty')

      @other_region.delete_all_empty_locations

      expect(Location.all.count).to eq(1)
      expect(Location.first.name).to eq('empty')
    end
  end

  describe '#generate_daily_digest_comments_email_body' do
    it 'should return nil if there are no comments that day' do
      FactoryGirl.create(:user_submission, region: @region, submission: 'bar', submission_type: UserSubmission::NEW_CONDITION_TYPE, created_at: DateTime.now - 2.day)
      FactoryGirl.create(:user_submission, region: @region, submission: 'baz', submission_type: UserSubmission::REMOVE_MACHINE_TYPE)

      expect(@region.generate_daily_digest_comments_email_body).to eq(nil)
    end

    it 'should generate a string containing all machine comments from the day' do
      FactoryGirl.create(:user_submission, region: @region, submission: 'foo', submission_type: UserSubmission::NEW_CONDITION_TYPE, created_at: DateTime.now - 1.day)
      FactoryGirl.create(:user_submission, region: @region, submission: 'bar', submission_type: UserSubmission::NEW_CONDITION_TYPE, created_at: DateTime.now - 1.day)

      FactoryGirl.create(:user_submission, region: @region, submission: 'bar', submission_type: UserSubmission::NEW_CONDITION_TYPE, created_at: DateTime.now - 2.day)
      FactoryGirl.create(:user_submission, region: @region, submission: 'baz', submission_type: UserSubmission::REMOVE_MACHINE_TYPE)

      expect(@region.generate_daily_digest_comments_email_body).to eq(<<HERE)
Here is a list of all the comments that were placed in your region on #{(DateTime.now - 1.day).strftime('%m/%d/%Y')}. Questions/concerns? Contact pinballmap@posteo.org

Portland Daily Comments

bar

foo
HERE
    end
  end

  describe '#generate_daily_digest_removals_email_body' do
    it 'should return nil if there are no removals that day' do
      FactoryGirl.create(:user_submission, region: @region, submission: 'bar', submission_type: UserSubmission::REMOVE_MACHINE_TYPE, created_at: DateTime.now - 2.day)
      FactoryGirl.create(:user_submission, region: @region, submission: 'baz', submission_type: UserSubmission::NEW_CONDITION_TYPE)

      expect(@region.generate_daily_digest_removals_email_body).to eq(nil)
    end

    it 'should generate a string containing all machine removals from the day' do
      FactoryGirl.create(:user_submission, region: @region, submission: 'foo', submission_type: UserSubmission::REMOVE_MACHINE_TYPE, created_at: DateTime.now - 1.day)
      FactoryGirl.create(:user_submission, region: @region, submission: 'bar', submission_type: UserSubmission::REMOVE_MACHINE_TYPE, created_at: DateTime.now - 1.day)

      FactoryGirl.create(:user_submission, region: @region, submission: 'bar', submission_type: UserSubmission::REMOVE_MACHINE_TYPE, created_at: DateTime.now - 2.day)
      FactoryGirl.create(:user_submission, region: @region, submission: 'baz', submission_type: UserSubmission::NEW_CONDITION_TYPE)

      expect(@region.generate_daily_digest_removals_email_body).to eq(<<HERE)
Here is a list of all the machines that were removed from your region on #{(DateTime.now - 1.day).strftime('%m/%d/%Y')}. Questions/concerns? Contact pinballmap@posteo.org

Portland Daily Machine Removals

bar

foo
HERE
    end
  end

  describe '#generate_weekly_admin_email_body' do
    it 'should generate a string containing metrics about the region condition' do
      FactoryGirl.create(:location, region: @another_region)

      FactoryGirl.create(:location, region: @region, name: 'Empty Location', city: 'Troy', state: 'OR')
      FactoryGirl.create(:location, region: @region, name: 'Another Empty Location', city: 'Rochester', state: 'OR', created_at: Date.today - 2.week)

      FactoryGirl.create(:user_submission, region: @region, submission_type: 'suggest_location')
      FactoryGirl.create(:user_submission, region: @region, submission_type: 'suggest_location')

      location_added_today = FactoryGirl.create(:location, region: @region)
      FactoryGirl.create(:location_machine_xref, location: location_added_today, machine: FactoryGirl.create(:machine))

      FactoryGirl.create(:user_submission, region: @region, submission_type: 'remove_machine')
      FactoryGirl.create(:user_submission, region: @region, submission_type: 'remove_machine')

      FactoryGirl.create(:location_machine_xref, location: location_added_today, machine: FactoryGirl.create(:machine), created_at: Date.today - 2.week)
      FactoryGirl.create(:location_machine_xref, location: location_added_today, machine: FactoryGirl.create(:machine), created_at: Date.today - 2.week)

      FactoryGirl.create(:event, region: @region, created_at: Date.today - 2.week)
      FactoryGirl.create(:event, region: @region, end_date: Date.today - 2.week)
      FactoryGirl.create(:event, region: @region)
      FactoryGirl.create(:event, region: @region)
      FactoryGirl.create(:event, region: @region)

      FactoryGirl.create(:user_submission, region: @region, submission_type: 'contact_us')
      FactoryGirl.create(:user_submission, region: @region, submission_type: 'contact_us')
      FactoryGirl.create(:user_submission, region: @region, submission_type: 'contact_us')
      FactoryGirl.create(:user_submission, region: @region, submission_type: 'contact_us')
      FactoryGirl.create(:user_submission, region: @region, submission_type: 'contact_us')

      expect(@region.generate_weekly_admin_email_body).to eq(<<HERE)
Here is an overview of your pinball map region! Thanks for keeping your region updated! Please remove any empty locations and add any submitted ones. Questions/concerns? Contact pinballmap@posteo.org

Portland Weekly Overview

List of Empty Locations:
Another Empty Location (Rochester, OR)
Empty Location (Troy, OR)

2 Location(s) submitted to you this week
2 Location(s) added by you this week
1 machine(s) added by users this week
2 machine(s) removed by users this week
Portland is listing 3 machines and 3 locations
4 event(s) listed
3 event(s) added this week
5 "contact us" message(s) sent to you
HERE
    end
  end

  describe '#n_recent_scores' do
    it 'should return the most recent n scores' do
      lmx = FactoryGirl.create(:location_machine_xref, location: FactoryGirl.create(:location, region: @region))
      one = FactoryGirl.create(:machine_score_xref, location_machine_xref: lmx, created_at: '2001-01-01')
      two = FactoryGirl.create(:machine_score_xref, location_machine_xref: lmx, created_at: '2001-02-01')
      FactoryGirl.create(:machine_score_xref, location_machine_xref: lmx, created_at: '2001-03-01')

      expect(@region.n_recent_scores(2)).to eq([one, two])
    end
  end

  describe '#n_high_rollers' do
    it 'should return the high n rollers' do
      scores = []
      lmx = FactoryGirl.create(:location_machine_xref, location: FactoryGirl.create(:location, region: @region))

      3.times { |n| scores << FactoryGirl.create(:machine_score_xref, location_machine_xref: lmx, user: FactoryGirl.create(:user, username: "ssw#{n}")) }
      scores << FactoryGirl.create(:machine_score_xref, location_machine_xref: lmx, user: User.find_by_username('ssw0'))

      expect(@region.n_high_rollers(1)).to include(
        'ssw0' => [scores[3], scores[0]]
      )
    end
  end

  describe '#emailContact' do
    it 'should return a default email address if no users are in region' do
      expect(@region.primary_email_contact).to eq('email_not_found@noemailfound.noemail')
    end
    it 'should return the primary email contact if they are flagged' do
      FactoryGirl.create(:user, region: @region, email: 'not@primary.com')
      FactoryGirl.create(:user, region: @region, email: 'is@primary.com', is_primary_email_contact: 1)

      expect(@region.primary_email_contact).to eq('is@primary.com')
    end
    it 'should return the first user if there is no primary email contact' do
      FactoryGirl.create(:user, region: @region, email: 'first@first.com')
      FactoryGirl.create(:user, region: @region, email: 'second@second.com')

      expect(@region.primary_email_contact).to eq('first@first.com')
    end
  end

  describe '#machinesless_locations' do
    it 'should return any location without a machine' do
      FactoryGirl.create(:location_machine_xref, location: FactoryGirl.create(:location, region: @region))
      FactoryGirl.create(:location_machine_xref, location: FactoryGirl.create(:location, region: @region))
      l = FactoryGirl.create(:location, region: @region)
      l2 = FactoryGirl.create(:location, region: @region)

      expect(@region.machineless_locations).to include(l, l2)
    end
  end

  describe '#locations_count' do
    it 'should return an int representing the number of locations in the region' do
      FactoryGirl.create(:location, region: @region)
      FactoryGirl.create(:location, region: @region)

      expect(@region.locations_count).to eq(2)
    end
  end

  describe '#machines_count' do
    it 'should return an int representing the number of machines in the region' do
      FactoryGirl.create(:location_machine_xref, location: FactoryGirl.create(:location, region: @region))
      FactoryGirl.create(:location_machine_xref, location: FactoryGirl.create(:location, region: @region))
      FactoryGirl.create(:location_machine_xref, location: FactoryGirl.create(:location, region: @region))
      FactoryGirl.create(:location_machine_xref, location: FactoryGirl.create(:location, region: @region))

      FactoryGirl.create(:location_machine_xref, location: FactoryGirl.create(:location, region: @other_region))

      expect(@region.machines_count).to eq(4)
    end
  end

  describe '#all_admin_email_addresses' do
    it 'should return a default email address if no users are in region' do
      expect(@region.all_admin_email_addresses).to eq(['email_not_found@noemailfound.noemail'])
    end
    it 'should return all admin email addresses' do
      FactoryGirl.create(:user, region: @region, email: 'not@primary.com')
      FactoryGirl.create(:user, region: @region, email: 'is@primary.com', is_primary_email_contact: 1)

      expect(@region.all_admin_email_addresses).to eq(['is@primary.com', 'not@primary.com'])
    end
  end

  describe '#available_search_sections' do
    it 'should not return zone as a search section if the region has no zones' do
      expect(@region.available_search_sections).to eq("['location', 'city', 'machine', 'type']")

      FactoryGirl.create(:location, region: @region, name: 'Cleo', zone: FactoryGirl.create(:zone, region: @region, name: 'Alberta'))

      expect(@region.reload.available_search_sections).to eq("['location', 'city', 'machine', 'type', 'zone']")
    end

    it 'should not return operator as a search section if the region has no operators' do
      expect(@region.available_search_sections).to eq("['location', 'city', 'machine', 'type']")

      FactoryGirl.create(:location, region: @region, name: 'Cleo', operator: FactoryGirl.create(:operator, name: 'Quarter Bean', region: @region))

      expect(@region.reload.available_search_sections).to eq("['location', 'city', 'machine', 'type', 'operator']")
    end

    it 'should display all search sections when an operator and zone are present' do
      FactoryGirl.create(:location, region: @region, name: 'Cleo', zone: FactoryGirl.create(:zone, region: @region, name: 'Alberta'))
      FactoryGirl.create(:location, region: @region, name: 'Cleo', operator: FactoryGirl.create(:operator, name: 'Quarter Bean', region: @region))

      expect(@region.reload.available_search_sections).to eq("['location', 'city', 'machine', 'type', 'operator', 'zone']")
    end
  end

  describe '#content_for_infowindow' do
    it 'generate the html that the infowindow wants to use' do
      r = FactoryGirl.create(:region, full_name: 'Portland')

      location = FactoryGirl.create(:location, region: r, name: 'Sassy')
      another_location = FactoryGirl.create(:location, region: r, name: 'Cleo')

      machine = FactoryGirl.create(:machine, name: 'Sassy')
      another_machine = FactoryGirl.create(:machine, name: 'Cleo')

      FactoryGirl.create(:location_machine_xref, location: location, machine: machine)
      FactoryGirl.create(:location_machine_xref, location: another_location, machine: machine)
      FactoryGirl.create(:location_machine_xref, location: another_location, machine: another_machine)

      expect(r.content_for_infowindow.chomp).to eq("'<div class=\"infowindow\" id=\"infowindow_#{r.id}\"><div class=\"gm_region_name\"><a href=\"#{r.name}\">Portland</a></div><hr /><div class=\"gm_location_count\">2 Locations</div><div class=\"gm_machine_count\">3 Machines</div></div>'")
    end
  end

  describe '#move_to_new_region' do
    it 'moves over all locations' do
      FactoryGirl.create(:location, region: @region, name: 'Sass')
      FactoryGirl.create(:location, region: @region, name: 'Cleo')

      @region.move_to_new_region(@other_region)

      expect(@region.locations.count).to eq(0)
      expect(@other_region.locations.count).to eq(2)
    end

    it 'moves over all events' do
      FactoryGirl.create(:event, region: @region, name: 'Sass')
      FactoryGirl.create(:event, region: @region, name: 'Cleo')

      @region.move_to_new_region(@other_region)

      expect(@region.events.count).to eq(0)
      expect(@other_region.events.count).to eq(2)
    end

    it 'moves over all operators' do
      FactoryGirl.create(:operator, region: @region, name: 'Sass')
      FactoryGirl.create(:operator, region: @region, name: 'Cleo')

      @region.move_to_new_region(@other_region)

      expect(@region.operators.count).to eq(0)
      expect(@other_region.operators.count).to eq(2)
    end

    it 'moves over all region_link_xrefs' do
      FactoryGirl.create(:region_link_xref, region: @region, name: 'Sass')
      FactoryGirl.create(:region_link_xref, region: @region, name: 'Cleo')

      @region.move_to_new_region(@other_region)

      expect(@region.region_link_xrefs.count).to eq(0)
      expect(@other_region.region_link_xrefs.count).to eq(2)
    end

    it 'moves over all admins' do
      FactoryGirl.create(:user, region: @region, username: 'Sass')
      FactoryGirl.create(:user, region: @region, username: 'Cleo')

      @region.move_to_new_region(@other_region)

      expect(@region.users.count).to eq(0)
      expect(@other_region.users.count).to eq(2)
    end

    it 'moves over all zones' do
      FactoryGirl.create(:zone, region: @region, name: 'Sass')
      FactoryGirl.create(:zone, region: @region, name: 'Cleo')

      @region.move_to_new_region(@other_region)

      expect(@region.zones.count).to eq(0)
      expect(@other_region.zones.count).to eq(2)
    end

    it 'moves over all user submissions' do
      FactoryGirl.create(:user_submission, region: @region)
      FactoryGirl.create(:user_submission, region: @region)

      @region.move_to_new_region(@other_region)

      expect(@region.user_submissions.count).to eq(0)
      expect(@other_region.user_submissions.count).to eq(2)
    end
  end
end
