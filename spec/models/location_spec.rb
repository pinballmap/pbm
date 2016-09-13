require 'spec_helper'

describe Location do
  before(:each) do
    @l = FactoryGirl.create(:location)
    @m1 = FactoryGirl.create(:machine, name: 'Sassy')
    @m2 = FactoryGirl.create(:machine, name: 'Cleo')
    @lmx1 = FactoryGirl.create(:location_machine_xref, location: @l, machine: @m1, created_at: '2014-01-15 04:00:00')
    @lmx2 = FactoryGirl.create(:location_machine_xref, location: @l, machine: @m2, created_at: '2014-01-15 05:00:00')
  end

  describe '#before_destroy' do
    it 'should clean up location_machine_xrefs, events, location_picture_xrefs' do
      FactoryGirl.create(:event, location: @l)
      FactoryGirl.create(:location_picture_xref, location: @l, photo: nil)

      @l.destroy

      expect(Event.all).to eq([])
      expect(LocationPictureXref.all).to eq([])
      expect(LocationMachineXref.all).to eq([])
      expect(MachineScoreXref.all).to eq([])
      expect(Location.all).to eq([])
    end
  end

  describe 'website validation' do
    it 'should allow blank websites' do
      @l.update_attributes(website: '')
      expect(lambda do
        @l.save!
      end).to_not raise_error
    end
    it 'should not update location with websites that do not start with http:// or https://' do
      @l.update_attributes(website: 'lol.com')
      expect(lambda do
        @l.save!
      end).to raise_error

      @l.update_attributes(website: 'http://lol.com')
      expect(lambda do
        @l.save!
      end).to_not raise_error

      @l.update_attributes(website: 'https://lol.com')
      expect(lambda do
        @l.save!
      end).to_not raise_error
    end
  end

  describe '#location_machine_xrefs' do
    it 'should return all machines for this location' do
      expect(@l.location_machine_xrefs.order(:id)).to eq([@lmx1, @lmx2])
    end
  end

  describe '#machine_names' do
    it 'should return all machine names for this location' do
      expect(@l.machine_names).to eq(%w(Cleo Sassy))
    end
  end

  describe '#content_for_infowindow' do
    it 'generate the html that the infowindow wants to use' do
      l = FactoryGirl.create(:location)
      ['Foo', 'Bar', 'Baz', "Beans'"].each { |name| FactoryGirl.create(:location_machine_xref, location: l, machine: FactoryGirl.create(:machine, name: name)) }

      expect(l.content_for_infowindow.chomp).to eq("'<div class=\"infowindow\" id=\"infowindow_#{l.id}\"><div class=\"gm_location_name\">Test Location Name</div><div class=\"gm_address\">303 Southeast 3rd Avenue<br />Portland, OR, 97214<br /></div><hr /><div class=\"gm_machines\" id=\"gm_machines_#{l.id}\">Bar<br />Baz<br />Beans\\'<br />Foo<br /></div></div>'")
    end
  end

  describe '#newest_machine_xref' do
    it 'should return the latest machine that has been added' do
      expect(@l.newest_machine_xref).to eq(@lmx2)
    end
  end

  describe '#massaged_name' do
    it 'ignores "the" in names' do
      the_location = FactoryGirl.create(:location, name: 'The Hilt')
      expect(the_location.massaged_name).to eq('Hilt')
    end
  end

  describe '#confirm' do
    it 'sets date_last_updated and last_updated_by_user_id' do
      user = FactoryGirl.create(:user, username: 'ssw')

      @l.confirm(user)

      expect(@l.last_updated_by_user_id).to eq(user.id)
      expect(@l.date_last_updated).to eq(Date.today)
    end

    it 'auto-creates user submissions' do
      user = FactoryGirl.create(:user, username: 'ssw')
      location = FactoryGirl.create(:location, name: 'foo')

      location.confirm(user)

      submission = UserSubmission.last

      expect(submission.user).to eq(user)
      expect(submission.region).to eq(location.region)
      expect(submission.location).to eq(location)
      expect(submission.submission).to eq('User ssw confirmed the lineup at foo')
      expect(submission.submission_type).to eq(UserSubmission::CONFIRM_LOCATION_TYPE)
    end
  end

  describe '#update_metadata' do
    it 'creates a user submission for updated metadata' do
      u = FactoryGirl.create(:user, username: 'ssw', email: 'yeah@ok.com')
      @l.update_metadata(u, description: 'foo')

      user_submission = UserSubmission.third

      expect(user_submission.user_id).to eq(u.id)
      expect(user_submission.submission).to eq('Changed location description to foo')
      expect(user_submission.location).to eq(@l)
    end

    it 'creates a user submission for updated metadata -- no user sent' do
      @l.update_metadata(nil, description: 'foo')

      user_submission = UserSubmission.third

      expect(user_submission.user_id).to eq(nil)
      expect(user_submission.submission).to eq('Changed location description to foo')
    end

    it 'creates a user submission for updated metadata -- all fields' do
      u = FactoryGirl.create(:user, username: 'ssw', email: 'yeah@ok.com')
      FactoryGirl.create(:operator, id: 1, name: 'operator')
      FactoryGirl.create(:location_type, id: 1, name: 'bar')

      @l.update_metadata(u, description: 'foo', phone: '555-555-5555', website: 'http://www.goo.com', operator_id: 1, location_type_id: 1)

      user_submission = UserSubmission.third

      expect(user_submission.user_id).to eq(u.id)
      expect(user_submission.submission).to eq(<<-HERE.strip)
Changed location description to foo
Changed phone # to 555-555-5555
Changed website to http://www.goo.com
Changed operator to operator
Changed location type to bar
HERE
    end

    it 'truncates location description to 254 characters' do
      u = FactoryGirl.create(:user, username: 'ssw', email: 'yeah@ok.com')
      @l.update_metadata(u, description: '1' * 300)

      expect(@l.description.size).to eq(254)
    end
  end
end
