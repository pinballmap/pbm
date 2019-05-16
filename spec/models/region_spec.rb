require 'spec_helper'

describe Region do
  before(:each) do
    @region = FactoryBot.create(:region, name: 'portland', full_name: 'Portland', should_auto_delete_empty_locations: 1)
    @other_region = FactoryBot.create(:region, name: 'chicago')
  end

  describe '#machine_and_location_count_by_region' do
    it 'should send back a count of all locations and machines in a region' do
      clark_location = FactoryBot.create(:location, region: @region, name: 'Clark')
      FactoryBot.create(:location, region: @region, name: 'Ripley')
      FactoryBot.create(:location, region: @other_region, name: 'Cleo')

      FactoryBot.create(:location_machine_xref, location: clark_location, machine: FactoryBot.create(:machine))
      FactoryBot.create(:location_machine_xref, location: clark_location, machine: FactoryBot.create(:machine))
      FactoryBot.create(:location_machine_xref, location: clark_location, machine: FactoryBot.create(:machine))

      expect(Region.machine_and_location_count_by_region).to include(
        @region.id => { 'locations_count' => 2, 'machines_count' => 3 },
        @other_region.id => { 'locations_count' => 1, 'machines_count' => 0 }
      )
    end
  end

  describe '#delete_empty_regionless_locations' do
    it 'should remove all empty regionless locations' do
      FactoryBot.create(:location, region: nil)
      not_empty = FactoryBot.create(:location, region: nil, name: 'not empty')
      FactoryBot.create(:location_machine_xref, location: not_empty, machine: FactoryBot.create(:machine))

      Region.delete_empty_regionless_locations

      expect(Location.all.count).to eq(1)
      expect(Location.first.name).to eq('not empty')
    end
  end

  describe '#delete_all_empty_locations' do
    it 'should remove all empty locations if the region has opted in to this functionality' do
      FactoryBot.create(:location, region: @region)
      not_empty = FactoryBot.create(:location, region: @region, name: 'not empty')
      FactoryBot.create(:location_machine_xref, location: not_empty, machine: FactoryBot.create(:machine))

      @region.delete_all_empty_locations

      expect(Location.all.count).to eq(1)
      expect(Location.first.name).to eq('not empty')
    end

    it 'should not remove all empty locations if the region has opted in to this functionality' do
      FactoryBot.create(:location, region: @other_region, name: 'empty')

      @other_region.delete_all_empty_locations

      expect(Location.all.count).to eq(1)
      expect(Location.first.name).to eq('empty')
    end
  end

  describe '#generate_daily_digest_comments_email_body' do
    it 'should return nil if there are no comments that day' do
      FactoryBot.create(:user_submission, region: @region, submission: 'bar', submission_type: UserSubmission::NEW_CONDITION_TYPE, created_at: Time.now - 2.day)
      FactoryBot.create(:user_submission, region: @region, submission: 'baz', submission_type: UserSubmission::REMOVE_MACHINE_TYPE)

      expect(@region.generate_daily_digest_comments_email_body).to eq(nil)
    end

    it 'should generate a string containing all machine comments from the day' do
      FactoryBot.create(:user_submission, region: @region, submission: 'foo', submission_type: UserSubmission::NEW_CONDITION_TYPE, created_at: Time.now - 1.day)
      FactoryBot.create(:user_submission, region: @region, submission: 'bar', submission_type: UserSubmission::NEW_CONDITION_TYPE, created_at: Time.now - 1.day)

      FactoryBot.create(:user_submission, region: @region, submission: 'bar', submission_type: UserSubmission::NEW_CONDITION_TYPE, created_at: Time.now - 2.day)
      FactoryBot.create(:user_submission, region: @region, submission: 'baz', submission_type: UserSubmission::REMOVE_MACHINE_TYPE)

      expect(@region.generate_daily_digest_comments_email_body).to eq(<<HERE)
Here is a list of all the comments that were placed in your region on #{(Time.now - 1.day).strftime('%m/%d/%Y')}. Questions/concerns? Contact map@pinballmap.com

Portland Daily Comments

bar

foo
HERE
    end
  end

  describe '#generate_daily_digest_regionless_comments_email_body' do
    it 'should return nil if there are no comments that day' do
      FactoryBot.create(:user_submission, region_id: nil, submission: 'bar', submission_type: UserSubmission::NEW_CONDITION_TYPE, created_at: Time.now - 2.day)
      FactoryBot.create(:user_submission, region: @region, submission: 'foo', submission_type: UserSubmission::NEW_CONDITION_TYPE, created_at: Time.now - 1.day)
      FactoryBot.create(:user_submission, region_id: nil, submission: 'baz', submission_type: UserSubmission::REMOVE_MACHINE_TYPE)

      expect(Region.generate_daily_digest_regionless_comments_email_body).to eq(nil)
    end

    it 'should generate a string containing all machine comments from the day' do
      FactoryBot.create(:user_submission, region: nil, submission: 'foo', submission_type: UserSubmission::NEW_CONDITION_TYPE, created_at: Time.now - 1.day)
      FactoryBot.create(:user_submission, region: nil, submission: 'bar', submission_type: UserSubmission::NEW_CONDITION_TYPE, created_at: Time.now - 1.day)

      FactoryBot.create(:user_submission, region: nil, submission: 'bar', submission_type: UserSubmission::NEW_CONDITION_TYPE, created_at: Time.now - 2.day)
      FactoryBot.create(:user_submission, region: nil, submission: 'baz', submission_type: UserSubmission::REMOVE_MACHINE_TYPE)

      expect(Region.generate_daily_digest_regionless_comments_email_body).to eq(<<HERE)
Here is a list of all the comments that were placed in regionless locations on #{(Time.now - 1.day).strftime('%m/%d/%Y')}.

REGIONLESS Daily Comments

bar

foo
HERE
    end
  end

  describe '#generate_daily_digest_regionless_removals_email_body' do
    it 'should return nil if there are no removals that day' do
      FactoryBot.create(:user_submission, region: nil, submission: 'bar', submission_type: UserSubmission::REMOVE_MACHINE_TYPE, created_at: Time.now - 2.day)
      FactoryBot.create(:user_submission, region: nil, submission: 'baz', submission_type: UserSubmission::NEW_CONDITION_TYPE)

      expect(Region.generate_daily_digest_regionless_removals_email_body).to eq(nil)
    end

    it 'should generate a string containing all machine removals from the day' do
      FactoryBot.create(:user_submission, region: nil, submission: 'foo', submission_type: UserSubmission::REMOVE_MACHINE_TYPE, created_at: Time.now - 1.day)
      FactoryBot.create(:user_submission, region: nil, submission: 'bar', submission_type: UserSubmission::REMOVE_MACHINE_TYPE, created_at: Time.now - 1.day)

      FactoryBot.create(:user_submission, region: nil, submission: 'bar', submission_type: UserSubmission::REMOVE_MACHINE_TYPE, created_at: Time.now - 2.day)
      FactoryBot.create(:user_submission, region: nil, submission: 'baz', submission_type: UserSubmission::NEW_CONDITION_TYPE)

      expect(Region.generate_daily_digest_regionless_removals_email_body).to eq(<<HERE)
Here is a list of all the machines that were removed from regionless locations on #{(Time.now - 1.day).strftime('%m/%d/%Y')}.

REGIONLESS Daily Machine Removals

bar

foo
HERE
    end
  end

  describe '#generate_daily_digest_removals_email_body' do
    it 'should return nil if there are no removals that day' do
      FactoryBot.create(:user_submission, region: @region, submission: 'bar', submission_type: UserSubmission::REMOVE_MACHINE_TYPE, created_at: Time.now - 2.day)
      FactoryBot.create(:user_submission, region: @region, submission: 'baz', submission_type: UserSubmission::NEW_CONDITION_TYPE)

      expect(@region.generate_daily_digest_removals_email_body).to eq(nil)
    end

    it 'should generate a string containing all machine removals from the day' do
      FactoryBot.create(:user_submission, region: @region, submission: 'foo', submission_type: UserSubmission::REMOVE_MACHINE_TYPE, created_at: Time.now - 1.day)
      FactoryBot.create(:user_submission, region: @region, submission: 'bar', submission_type: UserSubmission::REMOVE_MACHINE_TYPE, created_at: Time.now - 1.day)

      FactoryBot.create(:user_submission, region: @region, submission: 'bar', submission_type: UserSubmission::REMOVE_MACHINE_TYPE, created_at: Time.now - 2.day)
      FactoryBot.create(:user_submission, region: @region, submission: 'baz', submission_type: UserSubmission::NEW_CONDITION_TYPE)

      expect(@region.generate_daily_digest_removals_email_body).to eq(<<HERE)
Here is a list of all the machines that were removed from your region on #{(Time.now - 1.day).strftime('%m/%d/%Y')}. Questions/concerns? Contact map@pinballmap.com

Portland Daily Machine Removals

bar

foo
HERE
    end
  end

  describe '#generate_weekly_regionless_email_body' do
    it 'should generate a string containing metrics about regionless locations' do
      FactoryBot.create(:location, region: @region, name: 'Another Region Location')

      FactoryBot.create(:location, region: nil, name: 'Empty Location', city: 'Troy', state: 'OR')
      FactoryBot.create(:location, region: nil, name: 'Another Empty Location', city: 'Rochester', state: 'OR', created_at: Date.today - 2.week)

      FactoryBot.create(:user_submission, region: nil, submission_type: 'suggest_location')
      FactoryBot.create(:user_submission, region: nil, submission_type: 'suggest_location')

      FactoryBot.create(:user_submission, region: nil, submission_type: 'new_condition')
      FactoryBot.create(:user_submission, region: nil, submission_type: 'new_condition')

      location_added_today = FactoryBot.create(:location, region: nil, name: 'Location Added Today')
      FactoryBot.create(:location_machine_xref, location: location_added_today, machine: FactoryBot.create(:machine))

      FactoryBot.create(:user_submission, region: nil, submission_type: 'remove_machine')
      FactoryBot.create(:user_submission, region: nil, submission_type: 'remove_machine')

      FactoryBot.create(:user_submission, region: nil, submission_type: 'delete_location')
      FactoryBot.create(:user_submission, region: nil, submission_type: 'delete_location')
      FactoryBot.create(:user_submission, region: nil, submission_type: 'delete_location')

      FactoryBot.create(:location_machine_xref, location: location_added_today, machine: FactoryBot.create(:machine), created_at: Date.today - 2.week)
      FactoryBot.create(:location_machine_xref, location: location_added_today, machine: FactoryBot.create(:machine), created_at: Date.today - 2.week)

      FactoryBot.create(:suggested_location, region: nil, name: 'SL 1', machines: 'Batman')
      FactoryBot.create(:suggested_location, region: nil, name: 'SL 2', machines: 'Batman')

      expect(Region.generate_weekly_regionless_email_body).to eq(<<HERE)
Here is an overview of regionless locations! Please remove any empty locations and add any submitted ones. Questions/concerns? Contact map@pinballmap.com

Regionless Weekly Overview

List of Empty Locations:
Another Empty Location (Rochester, OR)
Empty Location (Troy, OR)

List of Suggested Locations:
SL 1
SL 2

2 Location(s) submitted to you this week
2 Location(s) added by you this week
3 Location(s) deleted this week
2 machine comment(s) by users this week
1 machine(s) added by users this week
2 machine(s) removed by users this week
REGIONLESS is listing 3 machines and 3 locations
HERE
    end
  end

  describe '#generate_weekly_admin_email_body' do
    it 'should generate a string containing metrics about the region condition' do
      FactoryBot.create(:location, region: @another_region)

      FactoryBot.create(:location, region: @region, name: 'Empty Location', city: 'Troy', state: 'OR')
      FactoryBot.create(:location, region: @region, name: 'Another Empty Location', city: 'Rochester', state: 'OR', created_at: Date.today - 2.week)

      FactoryBot.create(:user_submission, region: @region, submission_type: 'suggest_location')
      FactoryBot.create(:user_submission, region: @region, submission_type: 'suggest_location')

      FactoryBot.create(:user_submission, region: @region, submission_type: 'new_condition')
      FactoryBot.create(:user_submission, region: @region, submission_type: 'new_condition')

      location_added_today = FactoryBot.create(:location, region: @region)
      FactoryBot.create(:location_machine_xref, location: location_added_today, machine: FactoryBot.create(:machine))

      FactoryBot.create(:user_submission, region: @region, submission_type: 'remove_machine')
      FactoryBot.create(:user_submission, region: @region, submission_type: 'remove_machine')

      FactoryBot.create(:user_submission, region: @region, submission_type: 'delete_location')
      FactoryBot.create(:user_submission, region: @region, submission_type: 'delete_location')
      FactoryBot.create(:user_submission, region: @region, submission_type: 'delete_location')

      FactoryBot.create(:location_machine_xref, location: location_added_today, machine: FactoryBot.create(:machine), created_at: Date.today - 2.week)
      FactoryBot.create(:location_machine_xref, location: location_added_today, machine: FactoryBot.create(:machine), created_at: Date.today - 2.week)

      FactoryBot.create(:event, region: @region, created_at: Date.today - 2.week)
      FactoryBot.create(:event, region: @region, end_date: Date.today - 2.week)
      FactoryBot.create(:event, region: @region)
      FactoryBot.create(:event, region: @region)
      FactoryBot.create(:event, region: @region)

      FactoryBot.create(:user_submission, region: @region, submission_type: 'contact_us')
      FactoryBot.create(:user_submission, region: @region, submission_type: 'contact_us')
      FactoryBot.create(:user_submission, region: @region, submission_type: 'contact_us')
      FactoryBot.create(:user_submission, region: @region, submission_type: 'contact_us')
      FactoryBot.create(:user_submission, region: @region, submission_type: 'contact_us')

      FactoryBot.create(:suggested_location, region: @region, name: 'SL 1', machines: 'Batman')
      FactoryBot.create(:suggested_location, region: @region, name: 'SL 2', machines: 'Batman')

      expect(@region.generate_weekly_admin_email_body).to eq(<<HERE)
Here is an overview of your pinball map region! Thanks for keeping your region updated! Please remove any empty locations and add any submitted ones. Questions/concerns? Contact map@pinballmap.com

Portland Weekly Overview

List of Empty Locations:
Another Empty Location (Rochester, OR)
Empty Location (Troy, OR)

List of Suggested Locations:
SL 1
SL 2

2 Location(s) submitted to you this week
2 Location(s) added by you this week
3 Location(s) deleted this week
2 machine comment(s) by users this week
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
      lmx = FactoryBot.create(:location_machine_xref, location: FactoryBot.create(:location, region: @region))
      one = FactoryBot.create(:machine_score_xref, location_machine_xref: lmx, created_at: '2001-01-01')
      two = FactoryBot.create(:machine_score_xref, location_machine_xref: lmx, created_at: '2001-02-01')
      FactoryBot.create(:machine_score_xref, location_machine_xref: lmx, created_at: '2001-03-01')

      expect(@region.n_recent_scores(2)).to eq([one, two])
    end
  end

  describe '#n_high_rollers' do
    it 'should return the high n rollers' do
      scores = []
      lmx = FactoryBot.create(:location_machine_xref, location: FactoryBot.create(:location, region: @region))

      3.times { |n| scores << FactoryBot.create(:machine_score_xref, location_machine_xref: lmx, user: FactoryBot.create(:user, username: "ssw#{n}")) }
      scores << FactoryBot.create(:machine_score_xref, location_machine_xref: lmx, user: User.find_by_username('ssw0'))

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
      FactoryBot.create(:user, region: @region, email: 'not@primary.com')
      FactoryBot.create(:user, region: @region, email: 'is@primary.com', is_primary_email_contact: 1)

      expect(@region.primary_email_contact).to eq('is@primary.com')
    end
    it 'should return the first user if there is no primary email contact' do
      FactoryBot.create(:user, region: @region, email: 'first@first.com')
      FactoryBot.create(:user, region: @region, email: 'second@second.com')

      expect(@region.primary_email_contact).to eq('first@first.com')
    end
  end

  describe '#machinesless_locations' do
    it 'should return any location without a machine' do
      FactoryBot.create(:location_machine_xref, location: FactoryBot.create(:location, region: @region))
      FactoryBot.create(:location_machine_xref, location: FactoryBot.create(:location, region: @region))
      l = FactoryBot.create(:location, region: @region)
      l2 = FactoryBot.create(:location, region: @region)

      expect(@region.machineless_locations).to include(l, l2)
    end
  end

  describe '#locations_count' do
    it 'should return an int representing the number of locations in the region' do
      FactoryBot.create(:location, region: @region)
      FactoryBot.create(:location, region: @region)

      expect(@region.locations_count).to eq(2)
    end
  end

  describe '#machines_count' do
    it 'should return an int representing the number of machines in the region' do
      FactoryBot.create(:location_machine_xref, location: FactoryBot.create(:location, region: @region))
      FactoryBot.create(:location_machine_xref, location: FactoryBot.create(:location, region: @region))
      FactoryBot.create(:location_machine_xref, location: FactoryBot.create(:location, region: @region))
      FactoryBot.create(:location_machine_xref, location: FactoryBot.create(:location, region: @region))

      FactoryBot.create(:location_machine_xref, location: FactoryBot.create(:location, region: @other_region))

      expect(@region.machines_count).to eq(4)
    end
  end

  describe '#all_admin_email_addresses' do
    it 'should return a default email address if no users are in region' do
      expect(@region.all_admin_email_addresses).to eq(['email_not_found@noemailfound.noemail'])
    end
    it 'should return all admin email addresses' do
      FactoryBot.create(:user, region: @region, email: 'not@primary.com')
      FactoryBot.create(:user, region: @region, email: 'is@primary.com', is_primary_email_contact: 1)

      expect(@region.all_admin_email_addresses).to eq(['is@primary.com', 'not@primary.com'])
    end
  end

  describe '#available_search_sections' do
    it 'should not return zone as a search section if the region has no zones' do
      expect(@region.available_search_sections).to eq("['location', 'city', 'machine', 'type']")

      FactoryBot.create(:location, region: @region, name: 'Cleo', zone: FactoryBot.create(:zone, region: @region, name: 'Alberta'))

      expect(@region.reload.available_search_sections).to eq("['location', 'city', 'machine', 'type', 'zone']")
    end

    it 'should not return operator as a search section if the region has no operators OR there are no regionless operators' do
      expect(@region.available_search_sections).to eq("['location', 'city', 'machine', 'type']")

      FactoryBot.create(:operator, region: @region)

      expect(@region.reload.available_search_sections).to eq("['location', 'city', 'machine', 'type', 'operator']")

      Operator.delete_all
      FactoryBot.create(:operator, region: nil)

      expect(@region.reload.available_search_sections).to eq("['location', 'city', 'machine', 'type', 'operator']")
    end

    it 'should display all search sections when an operator and zone are present' do
      FactoryBot.create(:location, region: @region, name: 'Cleo', zone: FactoryBot.create(:zone, region: @region, name: 'Alberta'))
      FactoryBot.create(:location, region: @region, name: 'Cleo', operator: FactoryBot.create(:operator, name: 'Quarter Bean', region: @region))

      expect(@region.reload.available_search_sections).to eq("['location', 'city', 'machine', 'type', 'operator', 'zone']")
    end
  end

  describe '#content_for_infowindow' do
    it 'generate the html that the infowindow wants to use' do
      r = FactoryBot.create(:region, full_name: 'Portland')

      location = FactoryBot.create(:location, region: r, name: 'Sassy')
      another_location = FactoryBot.create(:location, region: r, name: 'Cleo')

      machine = FactoryBot.create(:machine, name: 'Sassy')
      another_machine = FactoryBot.create(:machine, name: 'Cleo')

      FactoryBot.create(:location_machine_xref, location: location, machine: machine)
      FactoryBot.create(:location_machine_xref, location: another_location, machine: machine)
      FactoryBot.create(:location_machine_xref, location: another_location, machine: another_machine)

      expect(r.content_for_infowindow(2, 3).chomp).to eq("'<div class=\"infowindow\" id=\"infowindow_#{r.id}\"><div class=\"gm_region_name\"><a href=\"#{r.name}\">Portland</a></div><hr /><div class=\"gm_location_count\">2 Locations</div><div class=\"gm_machine_count\">3 Machines</div></div>'")
    end
  end

  describe '#move_to_new_region' do
    it 'moves over all locations' do
      FactoryBot.create(:location, region: @region, name: 'Sass')
      FactoryBot.create(:location, region: @region, name: 'Cleo')

      @region.move_to_new_region(@other_region)

      expect(@region.locations.count).to eq(0)
      expect(@other_region.locations.count).to eq(2)
    end

    it 'moves over all events' do
      FactoryBot.create(:event, region: @region, name: 'Sass')
      FactoryBot.create(:event, region: @region, name: 'Cleo')

      @region.move_to_new_region(@other_region)

      expect(@region.events.count).to eq(0)
      expect(@other_region.events.count).to eq(2)
    end

    it 'moves over all operators' do
      FactoryBot.create(:operator, region: @region, name: 'Sass')
      FactoryBot.create(:operator, region: @region, name: 'Cleo')

      @region.move_to_new_region(@other_region)

      expect(@region.operators.count).to eq(0)
      expect(@other_region.operators.count).to eq(2)
    end

    it 'moves over all region_link_xrefs' do
      FactoryBot.create(:region_link_xref, region: @region, name: 'Sass')
      FactoryBot.create(:region_link_xref, region: @region, name: 'Cleo')

      @region.move_to_new_region(@other_region)

      expect(@region.region_link_xrefs.count).to eq(0)
      expect(@other_region.region_link_xrefs.count).to eq(2)
    end

    it 'moves over all admins' do
      FactoryBot.create(:user, region: @region, username: 'Sass')
      FactoryBot.create(:user, region: @region, username: 'Cleo')

      @region.move_to_new_region(@other_region)

      expect(@region.users.count).to eq(0)
      expect(@other_region.users.count).to eq(2)
    end

    it 'moves over all zones' do
      FactoryBot.create(:zone, region: @region, name: 'Sass')
      FactoryBot.create(:zone, region: @region, name: 'Cleo')

      @region.move_to_new_region(@other_region)

      expect(@region.zones.count).to eq(0)
      expect(@other_region.zones.count).to eq(2)
    end

    it 'moves over all user submissions' do
      FactoryBot.create(:user_submission, region: @region)
      FactoryBot.create(:user_submission, region: @region)

      @region.move_to_new_region(@other_region)

      expect(@region.user_submissions.count).to eq(0)
      expect(@other_region.user_submissions.count).to eq(2)
    end
  end

  describe '#motd' do
    it 'should return a default message if field is null or ryan-defined values' do
      expect(@region.motd).to eq('To help keep Pinball Map running, consider a donation! https://pinballmap.com/donate')

      @region.motd = 'foo'
      @region.save

      expect(@region.reload.motd).to eq('foo')
    end
  end

  describe '#random_location_id' do
    it 'should return a location_id from within a region' do
      rand_region = FactoryBot.create(:region, name: 'stjohns')
      FactoryBot.create(:location, id: 1000, region: rand_region)
      FactoryBot.create(:location, id: 1001, region: rand_region)
      FactoryBot.create(:location, id: 1002, region: rand_region)

      srand(0)

      expect(rand_region.random_location_id).to eq(1000)
    end
  end
end
