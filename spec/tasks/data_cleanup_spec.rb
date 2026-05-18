require 'spec_helper'

describe 'data_cleanup rake task' do
  before(:all) do
    Rails.application.load_tasks
  end

  def run_task
    Rake::Task['data_cleanup'].reenable
    Rake::Task['data_cleanup'].invoke
  end

  describe 'apostrophe_fix' do
    it 'replaces curly apostrophes in location names' do
      location = FactoryBot.create(:location, name: "Ryan’s Bar")
      run_task
      expect(location.reload.name).to eq("Ryan's Bar")
    end

    it 'does not modify names without curly apostrophes' do
      location = FactoryBot.create(:location, name: "Ryan's Bar")
      run_task
      expect(location.reload.name).to eq("Ryan's Bar")
    end
  end

  describe 'website_mobile_fix' do
    it 'replaces mobile facebook links with desktop facebook' do
      location = FactoryBot.create(:location, website: "https://m.facebook.com/coolpage")
      run_task
      expect(location.reload.website).to eq("https://facebook.com/coolpage")
    end
  end

  describe 'us_phone' do
    it 'formats a 10-digit US phone number' do
      location = FactoryBot.create(:location, phone: '5035551234', country: 'US')
      run_task
      expect(location.reload.phone).to eq('503-555-1234')
    end

    it 'does not format a non-US phone number' do
      location = FactoryBot.create(:location, phone: '5035551234', country: 'CA')
      run_task
      expect(location.reload.phone).to eq('5035551234')
    end

    it 'does not format a number that already contains non-digits' do
      location = FactoryBot.create(:location, phone: '503-555-1234', country: 'US')
      run_task
      expect(location.reload.phone).to eq('503-555-1234')
    end
  end

  describe 'user_submission_location_name' do
    let(:location) { FactoryBot.create(:location, name: 'New Name', city: 'Portland') }

    it 'updates a stale location_name' do
      us = FactoryBot.create(:user_submission,
        location: location, location_name: 'Old Name', city_name: 'Portland',
        submission_type: 'confirm_location', user_name: 'bob'
      )
      run_task
      expect(us.reload.location_name).to eq('New Name')
    end

    it 'updates a stale city_name' do
      us = FactoryBot.create(:user_submission,
        location: location, location_name: 'New Name', city_name: 'Old City',
        submission_type: 'confirm_location', user_name: 'bob'
      )
      run_task
      expect(us.reload.city_name).to eq('Portland')
    end

    it 'does not touch submissions where location_name and city_name are current' do
      us = FactoryBot.create(:user_submission,
        location: location, location_name: 'New Name', city_name: 'Portland',
        submission_type: 'confirm_location', user_name: 'bob',
        submission: 'untouched'
      )
      run_task
      expect(us.reload.submission).to eq('untouched')
    end

    it 'reconstructs submission text for new_lmx' do
      us = FactoryBot.create(:user_submission,
        location: location, location_name: 'Old Name', city_name: 'Portland',
        submission_type: 'new_lmx', user_name: 'bob', machine_name: 'Pinbot'
      )
      run_task
      expect(us.reload.submission).to eq('Pinbot was added to New Name in Portland by bob')
    end

    it 'reconstructs submission text for new_condition' do
      us = FactoryBot.create(:user_submission,
        location: location, location_name: 'Old Name', city_name: 'Portland',
        submission_type: 'new_condition', user_name: 'bob', machine_name: 'Pinbot',
        comment: 'plays great'
      )
      run_task
      expect(us.reload.submission).to eq('bob commented on Pinbot at New Name in Portland. They said: plays great')
    end

    it 'reconstructs submission text for remove_machine' do
      us = FactoryBot.create(:user_submission,
        location: location, location_name: 'Old Name', city_name: 'Portland',
        submission_type: 'remove_machine', user_name: 'bob', machine_name: 'Pinbot'
      )
      run_task
      expect(us.reload.submission).to eq('Pinbot was removed from New Name in Portland by bob')
    end

    it 'reconstructs submission text for new_msx' do
      us = FactoryBot.create(:user_submission,
        location: location, location_name: 'Old Name', city_name: 'Portland',
        submission_type: 'new_msx', user_name: 'bob', machine_name: 'Pinbot',
        high_score: 1_234_567
      )
      run_task
      expect(us.reload.submission).to eq('bob added a high score of 1,234,567 on Pinbot at New Name in Portland.')
    end

    it 'reconstructs submission text for confirm_location' do
      us = FactoryBot.create(:user_submission,
        location: location, location_name: 'Old Name', city_name: 'Portland',
        submission_type: 'confirm_location', user_name: 'bob'
      )
      run_task
      expect(us.reload.submission).to eq('bob confirmed the lineup at New Name in Portland')
    end

    it 'reconstructs submission text for ic_toggle' do
      us = FactoryBot.create(:user_submission,
        location: location, location_name: 'Old Name', city_name: 'Portland',
        submission_type: 'ic_toggle', user_name: 'bob', machine_name: 'Pinbot'
      )
      run_task
      expect(us.reload.submission).to eq('Insider Connected toggled on Pinbot at New Name in Portland by bob')
    end

    it 'reconstructs submission text for new_picture' do
      us = FactoryBot.create(:user_submission,
        location: location, location_name: 'Old Name', city_name: 'Portland',
        submission_type: 'new_picture', user_name: 'bob'
      )
      run_task
      expect(us.reload.submission).to eq('bob added a picture of New Name in Portland')
    end

    it 'reconstructs submission text for remove_picture' do
      us = FactoryBot.create(:user_submission,
        location: location, location_name: 'Old Name', city_name: 'Portland',
        submission_type: 'remove_picture', user_name: 'bob'
      )
      run_task
      expect(us.reload.submission).to eq('bob removed a picture of New Name in Portland')
    end

    it 'reconstructs submission text for add_location' do
      us = FactoryBot.create(:user_submission,
        location: location, location_name: 'Old Name', city_name: 'Portland',
        submission_type: 'add_location', user_name: 'bob'
      )
      run_task
      expect(us.reload.submission).to eq('New location added: New Name in Portland by bob')
    end

    it 'does not reconstruct submission text when field_presence? fails' do
      us = FactoryBot.create(:user_submission,
        location: location, location_name: 'Old Name', city_name: 'Portland',
        submission_type: 'confirm_location', user_name: nil,
        submission: 'original'
      )
      run_task
      expect(us.reload.submission).to eq('original')
    end
  end

  describe 'user_submission_user_name' do
    let(:user) { FactoryBot.create(:user, username: 'newname') }

    it 'updates a stale user_name' do
      us = FactoryBot.create(:user_submission,
        user: user, user_name: 'oldname', location_name: 'Some Bar',
        city_name: 'Portland', submission_type: 'confirm_location'
      )
      run_task
      expect(us.reload.user_name).to eq('newname')
    end

    it 'does not touch submissions where user_name is current' do
      us = FactoryBot.create(:user_submission,
        user: user, user_name: 'newname', location_name: 'Some Bar',
        city_name: 'Portland', submission_type: 'confirm_location',
        submission: 'untouched'
      )
      run_task
      expect(us.reload.submission).to eq('untouched')
    end

    it 'reconstructs submission text for new_lmx' do
      us = FactoryBot.create(:user_submission,
        user: user, user_name: 'oldname', location_name: 'Some Bar',
        city_name: 'Portland', submission_type: 'new_lmx', machine_name: 'Pinbot'
      )
      run_task
      expect(us.reload.submission).to eq('Pinbot was added to Some Bar in Portland by newname')
    end

    it 'reconstructs submission text for new_condition' do
      us = FactoryBot.create(:user_submission,
        user: user, user_name: 'oldname', location_name: 'Some Bar',
        city_name: 'Portland', submission_type: 'new_condition',
        machine_name: 'Pinbot', comment: 'plays great'
      )
      run_task
      expect(us.reload.submission).to eq('newname commented on Pinbot at Some Bar in Portland. They said: plays great')
    end

    it 'reconstructs submission text for remove_machine' do
      us = FactoryBot.create(:user_submission,
        user: user, user_name: 'oldname', location_name: 'Some Bar',
        city_name: 'Portland', submission_type: 'remove_machine', machine_name: 'Pinbot'
      )
      run_task
      expect(us.reload.submission).to eq('Pinbot was removed from Some Bar in Portland by newname')
    end

    it 'reconstructs submission text for new_msx' do
      us = FactoryBot.create(:user_submission,
        user: user, user_name: 'oldname', location_name: 'Some Bar',
        city_name: 'Portland', submission_type: 'new_msx',
        machine_name: 'Pinbot', high_score: 1_234_567
      )
      run_task
      expect(us.reload.submission).to eq('newname added a high score of 1,234,567 on Pinbot at Some Bar in Portland.')
    end

    it 'reconstructs submission text for confirm_location' do
      us = FactoryBot.create(:user_submission,
        user: user, user_name: 'oldname', location_name: 'Some Bar',
        city_name: 'Portland', submission_type: 'confirm_location'
      )
      run_task
      expect(us.reload.submission).to eq('newname confirmed the lineup at Some Bar in Portland')
    end

    it 'reconstructs submission text for ic_toggle' do
      us = FactoryBot.create(:user_submission,
        user: user, user_name: 'oldname', location_name: 'Some Bar',
        city_name: 'Portland', submission_type: 'ic_toggle', machine_name: 'Pinbot'
      )
      run_task
      expect(us.reload.submission).to eq('Insider Connected toggled on Pinbot at Some Bar in Portland by newname')
    end

    it 'reconstructs submission text for new_picture' do
      us = FactoryBot.create(:user_submission,
        user: user, user_name: 'oldname', location_name: 'Some Bar',
        city_name: 'Portland', submission_type: 'new_picture'
      )
      run_task
      expect(us.reload.submission).to eq('newname added a picture of Some Bar in Portland')
    end

    it 'reconstructs submission text for remove_picture' do
      us = FactoryBot.create(:user_submission,
        user: user, user_name: 'oldname', location_name: 'Some Bar',
        city_name: 'Portland', submission_type: 'remove_picture'
      )
      run_task
      expect(us.reload.submission).to eq('newname removed a picture of Some Bar in Portland')
    end

    it 'reconstructs submission text for add_location' do
      us = FactoryBot.create(:user_submission,
        user: user, user_name: 'oldname', location_name: 'Some Bar',
        city_name: 'Portland', submission_type: 'add_location'
      )
      run_task
      expect(us.reload.submission).to eq('New location added: Some Bar in Portland by newname')
    end

    it 'does not reconstruct submission text when field_presence? fails' do
      us = FactoryBot.create(:user_submission,
        user: user, user_name: 'oldname', location_name: nil,
        city_name: 'Portland', submission_type: 'confirm_location',
        submission: 'original'
      )
      run_task
      expect(us.reload.submission).to eq('original')
    end
  end

  describe 'delete_stale_locations' do
    it 'destroys locations not updated in over 7 years' do
      location = FactoryBot.create(:location)
      location.update_columns(date_last_updated: 8.years.ago)
      run_task
      expect(Location.find_by(id: location.id)).to be_nil
    end

    it 'does not destroy locations updated within 7 years' do
      location = FactoryBot.create(:location, date_last_updated: 1.year.ago)
      run_task
      expect(Location.find_by(id: location.id)).not_to be_nil
    end

    it 'does not destroy locations with no date_last_updated' do
      location = FactoryBot.create(:location)
      run_task
      expect(Location.find_by(id: location.id)).not_to be_nil
    end
  end

  describe 'delete_orphan_scores' do
    it 'destroys MachineScoreXrefs with no user' do
      score = FactoryBot.create(:machine_score_xref)
      score.update_columns(user_id: nil)
      run_task
      expect(MachineScoreXref.find_by(id: score.id)).to be_nil
    end

    it 'does not destroy MachineScoreXrefs that have a user' do
      score = FactoryBot.create(:machine_score_xref)
      run_task
      expect(MachineScoreXref.find_by(id: score.id)).not_to be_nil
    end
  end

  describe 'trim_location_fields' do
    it 'trims trailing spaces from name' do
      location = FactoryBot.create(:location)
      location.update_columns(name: 'Cool Bar ')
      run_task
      expect(location.reload.name).to eq('Cool Bar')
    end

    it 'trims trailing spaces from street' do
      location = FactoryBot.create(:location)
      location.update_columns(street: '123 Main St ')
      run_task
      expect(location.reload.street).to eq('123 Main St')
    end

    it 'trims trailing spaces from city' do
      location = FactoryBot.create(:location)
      location.update_columns(city: 'Portland ')
      run_task
      expect(location.reload.city).to eq('Portland')
    end

    it 'trims trailing spaces from zip' do
      location = FactoryBot.create(:location)
      location.update_columns(zip: '97214 ')
      run_task
      expect(location.reload.zip).to eq('97214')
    end

    it 'trims trailing spaces from state' do
      location = FactoryBot.create(:location)
      location.update_columns(state: 'OR ')
      run_task
      expect(location.reload.state).to eq('OR')
    end

    it 'trims trailing spaces from website' do
      location = FactoryBot.create(:location, website: 'http://example.com')
      location.update_columns(website: 'http://example.com ')
      run_task
      expect(location.reload.website).to eq('http://example.com')
    end

    it 'trims trailing spaces from phone' do
      location = FactoryBot.create(:location, phone: '503-555-1234')
      location.update_columns(phone: '503-555-1234 ')
      run_task
      expect(location.reload.phone).to eq('503-555-1234')
    end

    it 'does not modify fields without trailing spaces' do
      location = FactoryBot.create(:location, name: 'Clean Name')
      run_task
      expect(location.reload.name).to eq('Clean Name')
    end
  end

  describe 'normalize_street_addresses' do
    it 'abbreviates Boulevard at end of street' do
      location = FactoryBot.create(:location, street: '123 Sunset Boulevard')
      run_task
      expect(location.reload.street).to eq('123 Sunset Blvd')
    end

    it 'abbreviates Drive at end of street' do
      location = FactoryBot.create(:location, street: '456 Multnomah Drive')
      run_task
      expect(location.reload.street).to eq('456 Multnomah Dr')
    end

    it 'abbreviates Street at end of street' do
      location = FactoryBot.create(:location, street: '789 Burnside Street')
      run_task
      expect(location.reload.street).to eq('789 Burnside St')
    end

    it 'abbreviates Avenue at end of street' do
      location = FactoryBot.create(:location, street: '321 Alberta Avenue')
      run_task
      expect(location.reload.street).to eq('321 Alberta Ave')
    end

    it 'abbreviates Southwest anywhere in street' do
      location = FactoryBot.create(:location, street: '100 Southwest Barbur Blvd')
      run_task
      expect(location.reload.street).to eq('100 SW Barbur Blvd')
    end

    it 'abbreviates Southeast anywhere in street' do
      location = FactoryBot.create(:location, street: '200 Southeast Morrison St')
      run_task
      expect(location.reload.street).to eq('200 SE Morrison St')
    end

    it 'abbreviates Northwest anywhere in street' do
      location = FactoryBot.create(:location, street: '300 Northwest 23rd Ave')
      run_task
      expect(location.reload.street).to eq('300 NW 23rd Ave')
    end

    it 'abbreviates Northeast anywhere in street' do
      location = FactoryBot.create(:location, street: '400 Northeast Alberta St')
      run_task
      expect(location.reload.street).to eq('400 NE Alberta St')
    end

    it 'does not modify a street that is already abbreviated' do
      location = FactoryBot.create(:location, street: '123 Sunset Blvd')
      run_task
      expect(location.reload.street).to eq('123 Sunset Blvd')
    end

    it 'does not abbreviate Boulevard when it is not at the end of the street' do
      location = FactoryBot.create(:location, street: '123 Boulevard Heights Dr')
      run_task
      expect(location.reload.street).to eq('123 Boulevard Heights Dr')
    end
  end
end
