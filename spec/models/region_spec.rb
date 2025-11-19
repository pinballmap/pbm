require 'spec_helper'

describe Region do
  before(:each) do
    @region = FactoryBot.create(:region, name: 'portland', full_name: 'Portland', id: 77, should_auto_delete_empty_locations: 1)
    @other_region = FactoryBot.create(:region, id: 78, name: 'chicago')
  end

  describe '#before_destroy' do
    it 'should update timestamp in status table' do
      @status = FactoryBot.create(:status, status_type: 'regions', updated_at: Time.current - 1.day)
      @region.destroy

      expect(@status.reload.updated_at).to be_within(1.second).of Time.current
    end
  end

  describe '#create' do
    it 'should update timestamp in status table' do
      @status = FactoryBot.create(:status, status_type: 'regions', updated_at: Time.current - 1.day)
      FactoryBot.create(:region, name: 'glendale', id: 23345)

      expect(@status.reload.updated_at).to be_within(1.second).of Time.current
    end
  end

  describe '#update' do
    it 'should update timestamp in status table' do
      @status = FactoryBot.create(:status, status_type: 'regions', updated_at: Time.current - 1.day)
      @other_region.update(full_name: 'Chicago')

      expect(@status.reload.updated_at).to be_within(1.second).of Time.current
    end
  end

  describe '#delete_empty_regionless_locations' do
    it 'should remove all empty global locations' do
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

  describe '#delete_all_regionless_events' do
    it 'should remove all regionless events' do
      FactoryBot.create(:event, region: @region, name: 'New Event 1', start_date: Date.today, end_date: Date.today)
      FactoryBot.create(:event, region: nil, name: 'Event No Region', start_date: Date.today - 1.day)

      Region.delete_all_regionless_events

      expect(Event.all.count).to eq(1)
      expect(Event.first.name).to eq('New Event 1')
    end
  end

  describe '#delete_all_expired_events' do
    it 'should remove all expired events' do
      FactoryBot.create(:event, region: @region, name: 'Old Event 1', start_date: Date.today - 2.week, end_date: Date.today - 2.week)
      FactoryBot.create(:event, region: @region, name: 'Old Event 2', start_date: Date.today - 2.week)
      FactoryBot.create(:event, region: @region, name: 'New Event 1', start_date: Date.today, end_date: Date.today)
      FactoryBot.create(:event, region: @region, name: 'New Event 3', start_date: nil, end_date: Date.today)
      FactoryBot.create(:event, region: @region, name: 'New Event 2', start_date: Date.today)
      FactoryBot.create(:event, region: @region, name: 'Event No Date')

      @region.delete_all_expired_events

      expect(Event.all.count).to eq(3)
      expect(Event.first.name).to eq('New Event 1')
    end
  end

  describe '#generate_daily_digest_comments_email_body' do
    it 'should return nil if there are no comments that day' do
      FactoryBot.create(:user_submission, region_id: @region.id, submission: 'bar', submission_type: UserSubmission::NEW_CONDITION_TYPE, created_at: Time.now - 2.day)
      FactoryBot.create(:user_submission, region_id: @region.id, submission: 'baz', submission_type: UserSubmission::REMOVE_MACHINE_TYPE)

      expect(@region.generate_daily_digest_comments_email_body[:submissions]).to be_empty
    end

    it 'should generate a string containing all machine comments from the day' do
      FactoryBot.create(:user_submission, region_id: @region.id, submission: 'foo', submission_type: UserSubmission::NEW_CONDITION_TYPE, created_at: Time.now - 1.day)
      FactoryBot.create(:user_submission, region_id: @region.id, submission: 'bar', submission_type: UserSubmission::NEW_CONDITION_TYPE, created_at: Time.now - 1.day)

      FactoryBot.create(:user_submission, region_id: @region.id, submission: 'baz', submission_type: UserSubmission::NEW_CONDITION_TYPE, created_at: Time.now - 2.day)
      FactoryBot.create(:user_submission, region_id: @region.id, submission: 'qux', submission_type: UserSubmission::REMOVE_MACHINE_TYPE)

      expect(@region.generate_daily_digest_comments_email_body[:submissions]).to eq(%w[foo bar])
    end
  end

  describe '#generate_daily_digest_global_comments_email_body' do
    it 'should return nil if there are no comments that day' do
      FactoryBot.create(:user_submission, region_id: nil, submission: 'bar', submission_type: UserSubmission::NEW_CONDITION_TYPE, created_at: Time.now - 2.day)
      FactoryBot.create(:user_submission, region_id: @region.id, submission: 'foo', submission_type: UserSubmission::NEW_CONDITION_TYPE, created_at: Time.now - 2.day)
      FactoryBot.create(:user_submission, region_id: nil, submission: 'baz', submission_type: UserSubmission::REMOVE_MACHINE_TYPE)

      expect(Region.generate_daily_digest_global_comments_email_body[:submissions]).to be_empty
    end

    it 'should generate a string containing all machine comments from the day' do
      FactoryBot.create(:user_submission, region_id: nil, submission: 'foo', submission_type: UserSubmission::NEW_CONDITION_TYPE, created_at: Time.now - 1.day)
      FactoryBot.create(:user_submission, region_id: nil, submission: 'bar', submission_type: UserSubmission::NEW_CONDITION_TYPE, created_at: Time.now - 1.day)
      FactoryBot.create(:user_submission, region_id: @region.id, submission: 'bong', submission_type: UserSubmission::NEW_CONDITION_TYPE, created_at: Time.now - 1.day)

      FactoryBot.create(:user_submission, region_id: nil, submission: 'baz', submission_type: UserSubmission::NEW_CONDITION_TYPE, created_at: Time.now - 2.day)
      FactoryBot.create(:user_submission, region_id: nil, submission: 'qux', submission_type: UserSubmission::REMOVE_MACHINE_TYPE)

      expect(Region.generate_daily_digest_global_comments_email_body[:submissions]).to eq(%w[foo bar bong])
    end
  end

  describe '#generate_daily_digest_global_removal_email_body' do
    it 'should return nil if there are no removals that day' do
      FactoryBot.create(:user_submission, region: nil, submission: 'foo', submission_type: UserSubmission::REMOVE_MACHINE_TYPE, created_at: Time.now - 2.day)
      FactoryBot.create(:user_submission, region_id: @region.id, submission: 'bar', submission_type: UserSubmission::REMOVE_MACHINE_TYPE, created_at: Time.now - 2.day)
      FactoryBot.create(:user_submission, region: nil, submission: 'baz', submission_type: UserSubmission::NEW_CONDITION_TYPE)

      expect(Region.generate_daily_digest_global_removal_email_body[:submissions]).to be_empty
    end

    it 'should generate a string containing all machine removals from the day' do
      FactoryBot.create(:user_submission, region: nil, submission: 'foo', submission_type: UserSubmission::REMOVE_MACHINE_TYPE, created_at: Time.now - 1.day)
      FactoryBot.create(:user_submission, region: nil, submission: 'bar', submission_type: UserSubmission::REMOVE_MACHINE_TYPE, created_at: Time.now - 1.day)
      FactoryBot.create(:user_submission, region_id: @region.id, submission: 'bong', submission_type: UserSubmission::REMOVE_MACHINE_TYPE, created_at: Time.now - 1.day)

      FactoryBot.create(:user_submission, region: nil, submission: 'baz', submission_type: UserSubmission::REMOVE_MACHINE_TYPE, created_at: Time.now - 2.day)
      FactoryBot.create(:user_submission, region: nil, submission: 'qux', submission_type: UserSubmission::NEW_CONDITION_TYPE)

      expect(Region.generate_daily_digest_global_removal_email_body[:submissions]).to eq(%w[foo bar bong])
    end
  end

  describe '#generate_daily_digest_removal_email_body' do
    it 'should return nil if there are no removals that day' do
      FactoryBot.create(:user_submission, region: @region, submission: 'bar', submission_type: UserSubmission::REMOVE_MACHINE_TYPE, created_at: Time.now - 2.day)
      FactoryBot.create(:user_submission, region: @region, submission: 'baz', submission_type: UserSubmission::NEW_CONDITION_TYPE)

      expect(@region.generate_daily_digest_removal_email_body[:submissions]).to be_empty
    end

    it 'should generate a string containing all machine removals from the day' do
      FactoryBot.create(:user_submission, region: @region, submission: 'foo', submission_type: UserSubmission::REMOVE_MACHINE_TYPE, created_at: Time.now - 1.day)
      FactoryBot.create(:user_submission, region: @region, submission: 'bar', submission_type: UserSubmission::REMOVE_MACHINE_TYPE, created_at: Time.now - 1.day)

      FactoryBot.create(:user_submission, region: @region, submission: 'baz', submission_type: UserSubmission::REMOVE_MACHINE_TYPE, created_at: Time.now - 2.day)
      FactoryBot.create(:user_submission, region: @region, submission: 'qux', submission_type: UserSubmission::NEW_CONDITION_TYPE)

      expect(@region.generate_daily_digest_removal_email_body[:submissions]).to eq(%w[foo bar])
    end
  end

  describe '#generate_daily_digest_global_picture_added_email_body' do
    it 'should return nil if there are no pictures added that day' do
      FactoryBot.create(:user_submission, region: nil, submission: 'bar', submission_type: UserSubmission::NEW_PICTURE_TYPE, created_at: Time.now - 2.day)
      FactoryBot.create(:user_submission, region_id: @region.id, submission: 'bar', submission_type: UserSubmission::NEW_PICTURE_TYPE, created_at: Time.now - 2.day)
      FactoryBot.create(:user_submission, region: nil, submission: 'baz', submission_type: UserSubmission::NEW_PICTURE_TYPE)

      expect(Region.generate_daily_digest_global_picture_added_email_body[:submissions]).to be_empty
    end

    it 'should generate a string containing all pictures added from the day' do
      FactoryBot.create(:user_submission, region: nil, submission: 'foo', submission_type: UserSubmission::NEW_PICTURE_TYPE, created_at: Time.now - 1.day)
      FactoryBot.create(:user_submission, region: nil, submission: 'bar', submission_type: UserSubmission::NEW_PICTURE_TYPE, created_at: Time.now - 1.day)
      FactoryBot.create(:user_submission, region_id: @region.id, submission: 'bong', submission_type: UserSubmission::NEW_PICTURE_TYPE, created_at: Time.now - 1.day)

      FactoryBot.create(:user_submission, region: nil, submission: 'baz', submission_type: UserSubmission::NEW_PICTURE_TYPE, created_at: Time.now - 2.day)
      FactoryBot.create(:user_submission, region: nil, submission: 'qux', submission_type: UserSubmission::NEW_PICTURE_TYPE)

      expect(Region.generate_daily_digest_global_picture_added_email_body[:submissions]).to eq(%w[foo bar bong])
    end
  end

  describe '#generate_daily_digest_global_score_added_email_body' do
    it 'should return nil if there are no scores added that day' do
      FactoryBot.create(:user_submission, region: nil, submission: '111', submission_type: UserSubmission::NEW_SCORE_TYPE, created_at: Time.now - 2.day)
      FactoryBot.create(:user_submission, region_id: @region.id, submission: '222', submission_type: UserSubmission::NEW_SCORE_TYPE, created_at: Time.now - 2.day)
      FactoryBot.create(:user_submission, region: nil, submission: '333', submission_type: UserSubmission::NEW_SCORE_TYPE)

      expect(Region.generate_daily_digest_global_score_added_email_body[:submissions]).to be_empty
    end

    it 'should generate a string containing all scores added from the day' do
      FactoryBot.create(:user_submission, region: nil, submission: '444', submission_type: UserSubmission::NEW_SCORE_TYPE, created_at: Time.now - 1.day)
      FactoryBot.create(:user_submission, region: nil, submission: '555', submission_type: UserSubmission::NEW_SCORE_TYPE, created_at: Time.now - 1.day)
      FactoryBot.create(:user_submission, region_id: @region.id, submission: '666', submission_type: UserSubmission::NEW_SCORE_TYPE, created_at: Time.now - 1.day)

      FactoryBot.create(:user_submission, region: nil, submission: '777', submission_type: UserSubmission::NEW_SCORE_TYPE, created_at: Time.now - 2.day)
      FactoryBot.create(:user_submission, region: nil, submission: '888', submission_type: UserSubmission::NEW_SCORE_TYPE)

      expect(Region.generate_daily_digest_global_score_added_email_body[:submissions]).to eq(%w[444 555 666])
    end
  end

  describe '#generate_weekly_global_email_body' do
    it 'should generate a string containing metrics about global locations' do
      FactoryBot.create(:location, region: @region, name: 'Another Region Location')

      FactoryBot.create(:location, region: nil, name: 'Empty Location', city: 'Troy', state: 'OR')
      FactoryBot.create(:location, region: nil, name: 'Another Empty Location', city: 'Rochester', state: 'OR', created_at: Date.today - 2.week)

      FactoryBot.create(:user_submission, region: nil, submission_type: 'suggest_location')
      FactoryBot.create(:user_submission, region_id: @region.id, submission_type: 'suggest_location')

      FactoryBot.create(:user_submission, region: nil, submission_type: 'new_condition')
      FactoryBot.create(:user_submission, region_id: @region.id, submission_type: 'new_condition')
      FactoryBot.create(:user_submission, region_id: @region.id, submission_type: 'new_condition', deleted_at: Date.today)

      location_added_today = FactoryBot.create(:location, region: nil, name: 'Location Added Today')
      FactoryBot.create(:location_machine_xref, location: location_added_today, machine: FactoryBot.create(:machine))

      FactoryBot.create(:user_submission, region: nil, submission_type: 'new_lmx')
      FactoryBot.create(:user_submission, region: nil, submission_type: 'new_lmx')
      FactoryBot.create(:user_submission, region_id: @region.id, submission_type: 'new_lmx')
      FactoryBot.create(:user_submission, region: @region, submission_type: 'new_lmx',  created_at: Date.today - 2.week)

      FactoryBot.create(:user_submission, region: nil, submission_type: 'remove_machine')
      FactoryBot.create(:user_submission, region_id: @region.id, submission_type: 'remove_machine')

      FactoryBot.create(:user_submission, region: nil, submission_type: 'new_msx')
      FactoryBot.create(:user_submission, region_id: @region.id, submission_type: 'new_msx')
      FactoryBot.create(:user_submission, region_id: @region.id, submission_type: 'new_msx', deleted_at: Date.today)

      FactoryBot.create(:user_submission, region: nil, submission_type: 'delete_location')
      FactoryBot.create(:user_submission, region_id: @region.id, submission_type: 'delete_location')
      FactoryBot.create(:user_submission, region: nil, submission_type: 'delete_location')

      FactoryBot.create(:user_submission, region: nil, submission: 'foo', submission_type: UserSubmission::NEW_PICTURE_TYPE, created_at: Time.now - 1.day)
      FactoryBot.create(:user_submission, region_id: @region.id, submission: 'bar', submission_type: UserSubmission::NEW_PICTURE_TYPE, created_at: Time.now - 1.day)

      expect(Region.generate_weekly_global_email_body[:machineless_locations]).to eq([ 'Another Region Location (Portland, OR)', 'Empty Location (Troy, OR)', 'Another Empty Location (Rochester, OR)' ])
      expect(Region.generate_weekly_global_email_body[:suggested_locations_count]).to eq(2)
      expect(Region.generate_weekly_global_email_body[:locations_added_count]).to eq(3)
      expect(Region.generate_weekly_global_email_body[:locations_deleted_count]).to eq(3)
      expect(Region.generate_weekly_global_email_body[:machine_comments_count]).to eq(2)
      expect(Region.generate_weekly_global_email_body[:machines_added_count]).to eq(4)
      expect(Region.generate_weekly_global_email_body[:machines_removed_count]).to eq(2)
      expect(Region.generate_weekly_global_email_body[:pictures_added_count]).to eq(2)
      expect(Region.generate_weekly_global_email_body[:scores_added_count]).to eq(2)
      expect(Region.generate_weekly_global_email_body[:scores_deleted_count]).to eq(1)
      expect(Region.generate_weekly_global_email_body[:machine_comments_deleted_count]).to eq(1)
    end
  end

  describe '#generate_weekly_admin_email_body' do
    it 'should generate a string containing metrics about the region condition' do
      FactoryBot.create(:location, region: @another_region)

      FactoryBot.create(:location, region: @region, name: 'Empty Location', city: 'Troy', state: 'OR')
      FactoryBot.create(:location, region: @region, name: 'Another Empty Location', city: 'Rochester', state: 'OR', created_at: Date.today - 2.week)

      FactoryBot.create(:user_submission, region: @region, submission_type: 'suggest_location')
      FactoryBot.create(:user_submission, region: @region, submission_type: 'suggest_location')
      FactoryBot.create(:user_submission, region: @another_region, submission_type: 'suggest_location')

      FactoryBot.create(:user_submission, region: @region, submission_type: 'new_condition')
      FactoryBot.create(:user_submission, region: @region, submission_type: 'new_condition')
      FactoryBot.create(:user_submission, region: @another_region, submission_type: 'new_condition')

      location_added_today = FactoryBot.create(:location, region: @region)
      FactoryBot.create(:user_submission, region: @region, location: location_added_today, submission_type: 'new_lmx')

      FactoryBot.create(:user_submission, region: @region, submission_type: 'remove_machine')
      FactoryBot.create(:user_submission, region: @region, submission_type: 'remove_machine')
      FactoryBot.create(:user_submission, region: @another_region, submission_type: 'remove_machine')

      FactoryBot.create(:user_submission, region: @region, submission_type: 'delete_location')
      FactoryBot.create(:user_submission, region: @region, submission_type: 'delete_location')
      FactoryBot.create(:user_submission, region: @region, submission_type: 'delete_location')
      FactoryBot.create(:user_submission, region: @another_region, submission_type: 'delete_location')

      FactoryBot.create(:user_submission, region: nil, submission_type: 'new_msx')
      FactoryBot.create(:user_submission, region_id: @region.id, submission_type: 'new_msx')
      FactoryBot.create(:user_submission, region_id: @region.id, submission_type: 'new_msx')

      FactoryBot.create(:user_submission, region: @region, submission_type: 'new_lmx')
      FactoryBot.create(:user_submission, region: @region, submission_type: 'new_lmx')
      FactoryBot.create(:user_submission, region: @another_region, submission_type: 'new_lmx')
      FactoryBot.create(:user_submission, region: @region, submission_type: 'new_lmx',  created_at: Date.today - 2.week)

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
      FactoryBot.create(:user_submission, region: @another_region, submission_type: 'contact_us')

      FactoryBot.create(:suggested_location, region: @region, name: 'SL 1', machines: 'Batman')
      FactoryBot.create(:suggested_location, region: @region, name: 'SL 2', machines: 'Batman')

      FactoryBot.create(:user_submission, region: @region, submission: 'foo', submission_type: UserSubmission::NEW_PICTURE_TYPE, created_at: Time.now - 1.day)
      FactoryBot.create(:user_submission, region: @region, submission: 'bar', submission_type: UserSubmission::NEW_PICTURE_TYPE, created_at: Time.now - 1.day)

      expect(@region.generate_weekly_admin_email_body[:suggested_locations]).to eq([ 'SL 1', 'SL 2' ])
      expect(@region.generate_weekly_admin_email_body[:machineless_locations]).to eq([ 'Empty Location (Troy, OR)', 'Another Empty Location (Rochester, OR)', 'Test Location Name (Portland, OR)' ])
      expect(@region.generate_weekly_admin_email_body[:suggested_locations_count]).to eq(2)
      expect(@region.generate_weekly_admin_email_body[:locations_added_count]).to eq(2)
      expect(@region.generate_weekly_admin_email_body[:locations_deleted_count]).to eq(3)
      expect(@region.generate_weekly_admin_email_body[:machine_comments_count]).to eq(2)
      expect(@region.generate_weekly_admin_email_body[:machines_added_count]).to eq(3)
      expect(@region.generate_weekly_admin_email_body[:machines_removed_count]).to eq(2)
      expect(@region.generate_weekly_admin_email_body[:contact_messages_count]).to eq(5)
      expect(@region.generate_weekly_admin_email_body[:events_count]).to eq(5)
      expect(@region.generate_weekly_admin_email_body[:pictures_added_count]).to eq(2)
      expect(@region.generate_weekly_admin_email_body[:scores_added_count]).to eq(2)
      expect(@region.generate_weekly_admin_email_body[:full_name]).to eq('Portland')
    end
  end

  describe '#n_recent_scores' do
    it 'should return the most recent n scores' do
      lmx = FactoryBot.create(:location_machine_xref, location: FactoryBot.create(:location, region: @region))
      one = FactoryBot.create(:machine_score_xref, location_machine_xref: lmx, created_at: '2001-01-01')
      two = FactoryBot.create(:machine_score_xref, location_machine_xref: lmx, created_at: '2001-02-01')
      FactoryBot.create(:machine_score_xref, location_machine_xref: lmx, created_at: '2001-03-01')

      expect(@region.n_recent_scores(2)).to eq([ one, two ])
    end
  end

  describe '#n_high_rollers' do
    it 'should return the high n rollers' do
      scores = []
      lmx = FactoryBot.create(:location_machine_xref, location: FactoryBot.create(:location, region: @region))

      3.times { |n| scores << FactoryBot.create(:machine_score_xref, location_machine_xref: lmx, user: FactoryBot.create(:user, username: "ssw#{n}")) }
      scores << FactoryBot.create(:machine_score_xref, location_machine_xref: lmx, user: User.find_by_username('ssw0'))

      expect(@region.n_high_rollers(1)).to include(
        'ssw0' => [ scores[3], scores[0] ]
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
      expect(@region.all_admin_email_addresses).to eq([ 'email_not_found@noemailfound.noemail' ])
    end
    it 'should return all admin email addresses' do
      FactoryBot.create(:user, region: @region, email: 'not@primary.com')
      FactoryBot.create(:user, region: @region, email: 'is@primary.com', is_primary_email_contact: 1)

      expect(@region.all_admin_email_addresses).to eq([ 'is@primary.com', 'not@primary.com' ])
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
end
