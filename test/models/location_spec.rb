require 'spec_helper'

describe Location do
  before(:each) do
    @l = FactoryBot.create(:location, name: 'quarterworld')
    @m1 = FactoryBot.create(:machine, id: 200, name: 'Sassy')
    @m2 = FactoryBot.create(:machine, id: 201, name: 'Cleo')
    @lmx1 = FactoryBot.create(:location_machine_xref, location: @l, machine: @m1, created_at: '2014-01-15 04:00:00')
    @lmx2 = FactoryBot.create(:location_machine_xref, location: @l, machine: @m2, created_at: '2014-01-15 05:00:00')
  end

  describe '#user_fave?' do
    it 'tells you if the location is a fave of the user passed in as a param' do
      user = FactoryBot.create(:user)
      location = FactoryBot.create(:location)
      other_location = FactoryBot.create(:location)

      FactoryBot.create(:user_fave_location, user: user, location: location)
      FactoryBot.create(:user_fave_location, location: other_location)

      expect(location.user_fave?(user.id)).must_be :truthy?
      expect(other_location.user_fave?(user.id)).wont_be :truthy?
    end
  end

  describe 'respects user_faved scope' do
    it 'should filter to locations that the user has faved' do
      user = FactoryBot.create(:user)
      location = FactoryBot.create(:location)
      other_location = FactoryBot.create(:location)

      FactoryBot.create(:user_fave_location, user: user, location: location)
      FactoryBot.create(:user_fave_location, user: user, location: other_location)

      FactoryBot.create(:user_fave_location, location: location)

      expect(Location.user_faved(user.id)).must_equal [location, other_location]
    end
  end

  describe 'validates phone' do
    it 'only allows valid formats' do
      [
        '503-796-9364',
        '(503) 796-9364',
        '+61 8 8952 2355',
        '+49-89-636-48018',
        '+47 930 48 892'
      ].each do |p|
        @l.phone = p
        expect { @l.save! }.to_not raise_error
      end

      @l.phone = 'ABC'

      expect { @l.save! }.must_raise
    end
  end

  describe '#skip_geocoding?' do
    it 'respects lat/lon last updated status' do
      @l.last_updated_by_user_id = FactoryBot.create(:user, region_id: 1).id
      @l.lat = 1
      @l.lon = 1

      ENV['SKIP_GEOCODE'] = '0'
      expect(@l.skip_geocoding?).must_be :truthy?
      ENV['SKIP_GEOCODE'] = '1'
    end
  end

  describe '#before_destroy' do
    it 'should clean up location_machine_xrefs, events, location_picture_xrefs, user_fave_locations' do
      FactoryBot.create(:event, location: @l)
      FactoryBot.create(:location_picture_xref, location: @l, photo: nil)
      FactoryBot.create(:user_fave_location, location: @l)

      @l.destroy

      expect(Event.all).must_equal []
      expect(LocationPictureXref.all).must_equal []
      expect(LocationMachineXref.all).must_equal []
      expect(MachineScoreXref.all).must_equal []
      expect(Location.all).must_equal []
      expect(UserFaveLocation.all).must_equal []
    end
  end

  describe 'website validation' do
    RSpec::Expectations.configuration.on_potential_false_positives = :nothing

    it 'should allow blank websites' do
      @l.update(website: '')
      expect { @l.save! }.to_not raise_error
    end
    it 'should not update location with websites that do not start with http:// or https://' do
      @l.update(website: 'lol.com')
      expect { @l.save! }.must_raise

      @l.update(website: 'http://lol.com')
      expect { @l.save! }.to_not raise_error

      @l.update(website: 'https://lol.com')
      expect { @l.save! }.to_not raise_error
    end
  end

  describe '#location_machine_xrefs' do
    it 'should return all machines for this location' do
      expect(@l.location_machine_xrefs.order(:id)).must_equal [@lmx1, @lmx2]
    end
  end

  describe '#machine_names' do
    it 'should return all machine names for this location' do
      expect(@l.machine_names).must_equal %w[Cleo Sassy]
    end
  end

  describe '#machine_ids' do
    it 'should return all machine ids for this location' do
      expect(@l.machine_ids).must_equal [201, 200]
    end
  end

  describe '#massaged_name' do
    it 'ignores "the" in names' do
      the_location = FactoryBot.create(:location, name: 'The Hilt')
      expect(the_location.massaged_name).must_equal 'Hilt'
    end
  end

  describe '#confirm' do
    it 'sets date_last_updated and last_updated_by_user_id' do
      user = FactoryBot.create(:user, username: 'ssw')

      @l.confirm(user)

      expect(@l.last_updated_by_user_id).must_equal user.id
      expect(@l.date_last_updated).must_equal Date.today
    end

    it 'auto-creates user submissions' do
      user = FactoryBot.create(:user, username: 'ssw')
      location = FactoryBot.create(:location, name: 'foo', city: 'Portland')

      location.confirm(user)

      submission = UserSubmission.last

      expect(submission.user).must_equal user
      expect(submission.region).must_equal location.region
      expect(submission.location).must_equal location
      expect(submission.submission).must_equal 'ssw confirmed the lineup at foo in Portland'
      expect(submission.submission_type).must_equal UserSubmission::CONFIRM_LOCATION_TYPE
    end

    it 'works with regionless locations' do
      user = FactoryBot.create(:user, username: 'ssw')
      regionless_location = FactoryBot.create(:location, name: 'foo', region: nil)

      regionless_location.confirm(user)

      submission = UserSubmission.last

      expect(submission.region).must_equal nil
      expect(submission.submission_type).must_equal UserSubmission::CONFIRM_LOCATION_TYPE
    end
  end

  describe '#num_machines' do
    it 'should send back a number indicating the number of machines at the location' do
      expect(@l.num_machines).must_equal 2
    end
  end

  describe 'by_location_name scope' do
    it 'should search on normal apostrophes and weird iOS ones' do
      clark_location = FactoryBot.create(:location, name: "Clark's Castle")
      clark_other_location = FactoryBot.create(:location, name: 'Clark’s Castle')

      expect(Location.by_location_name("Clark's")).must_equal [clark_location, clark_other_location]
      expect(Location.by_location_name('Clark’s')).must_equal [clark_location, clark_other_location]
    end
  end

  describe '#update_metadata' do
    it 'works with a regionless location' do
      regionless_location = FactoryBot.create(:location, name: 'REGIONLESS', region: nil)
      u = FactoryBot.create(:user, username: 'ssw', email: 'yeah@ok.com')
      regionless_location.update_metadata(u, description: 'foo')

      user_submission = UserSubmission.third

      expect(user_submission.user_id).must_equal u.id
      expect(user_submission.submission).must_equal 'Changed location description to foo to REGIONLESS'
      expect(user_submission.location).must_equal regionless_location
      expect(user_submission.region).must_equal nil
    end

    it 'creates a user submission for updated metadata' do
      u = FactoryBot.create(:user, username: 'ssw', email: 'yeah@ok.com')
      @l.update_metadata(u, description: 'foo')

      user_submission = UserSubmission.third

      expect(user_submission.user_id).must_equal u.id
      expect(user_submission.submission).must_equal 'Changed location description to foo to quarterworld'
      expect(user_submission.location).must_equal @l
    end

    it 'creates a user submission for updated metadata -- no user sent' do
      @l.update_metadata(nil, description: 'foo')

      user_submission = UserSubmission.third

      expect(user_submission.user_id).must_equal nil
      expect(user_submission.submission).must_equal 'Changed location description to foo to quarterworld'
    end

    it 'creates a user submission for updated metadata -- all fields' do
      u = FactoryBot.create(:user, username: 'ssw', email: 'yeah@ok.com')
      FactoryBot.create(:operator, id: 1, name: 'operator')
      FactoryBot.create(:location_type, id: 1, name: 'bar')

      @l.update_metadata(u, description: 'foo', phone: '(503) 796-9364', website: 'http://www.goo.com', operator_id: 1, location_type_id: 1)

      user_submission = UserSubmission.third

      expect(user_submission.user_id).must_equal u.id
      expect(user_submission.submission).must_equal <<-HERE.strip
Changed location description to foo
Changed phone # to (503) 796-9364
Changed website to http://www.goo.com
Changed operator to operator
Changed location type to bar to quarterworld
      HERE
    end

    it 'truncates location description to 549 characters' do
      u = FactoryBot.create(:user, username: 'ssw', email: 'yeah@ok.com')
      @l.update_metadata(u, description: '1' * 600)

      expect(@l.description.size).must_equal 549
    end
  end
end
