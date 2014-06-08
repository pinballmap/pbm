require 'spec_helper'

describe Region do
  before(:each) do
    @r = FactoryGirl.create(:region, :name => 'portland')
    @other_region = FactoryGirl.create(:region, :name => 'chicago')
  end

  describe '#n_recent_scores' do
    it 'should return the most recent n scores' do
      lmx = FactoryGirl.create(:location_machine_xref, :location => FactoryGirl.create(:location, :region => @r))
      one = FactoryGirl.create(:machine_score_xref, :location_machine_xref => lmx, :created_at => '2001-01-01')
      two = FactoryGirl.create(:machine_score_xref, :location_machine_xref => lmx, :created_at => '2001-02-01')
      three = FactoryGirl.create(:machine_score_xref, :location_machine_xref => lmx, :created_at => '2001-03-01')

      @r.n_recent_scores(2).should == [one, two]
    end
  end

  describe '#n_high_rollers' do
    it 'should return the high n rollers' do
      scores = Array.new
      lmx = FactoryGirl.create(:location_machine_xref, :location => FactoryGirl.create(:location, :region => @r))

      3.times {|n| scores << FactoryGirl.create(:machine_score_xref, :location_machine_xref => lmx, :initials => "ssw#{n}")}
      scores << FactoryGirl.create(:machine_score_xref, :location_machine_xref => lmx, :initials => "ssw0")

      @r.n_high_rollers(2).should == {
        "ssw0" => [scores[3], scores[0]],
        "ssw2" => [scores[2]],
      }
    end
  end

  describe '#emailContact' do
    it 'should return a default email address if no users are in region' do
      @r.primary_email_contact.should == 'email_not_found@noemailfound.noemail'
    end
    it 'should return the primary email contact if they are flagged' do
      FactoryGirl.create(:user, :region => @r, :email => 'not@primary.com')
      FactoryGirl.create(:user, :region => @r, :email => 'is@primary.com', :is_primary_email_contact => 1)

      @r.primary_email_contact.should == 'is@primary.com'
    end
    it 'should return the first user if there is no primary email contact' do
      FactoryGirl.create(:user, :region => @r, :email => 'first@first.com')
      FactoryGirl.create(:user, :region => @r, :email => 'second@second.com')

      @r.primary_email_contact.should == 'first@first.com'
    end
  end

  describe '#machinesless_locations' do
    it 'should return any location without a machine' do
      FactoryGirl.create(:location_machine_xref, :location => FactoryGirl.create(:location, :region => @r))
      FactoryGirl.create(:location_machine_xref, :location => FactoryGirl.create(:location, :region => @r))
      l = FactoryGirl.create(:location, :region => @r)
      l2 = FactoryGirl.create(:location, :region => @r)

      @r.machineless_locations.should == [l, l2]
    end
  end

  describe '#locations_count' do
    it 'should return an int representing the number of locations in the region' do
      FactoryGirl.create(:location, :region => @r)
      FactoryGirl.create(:location, :region => @r)

      @r.locations_count.should == 2
    end
  end

  describe '#machines_count' do
    it 'should return an int representing the number of machines in the region' do
      FactoryGirl.create(:location_machine_xref, :location => FactoryGirl.create(:location, :region => @r))
      FactoryGirl.create(:location_machine_xref, :location => FactoryGirl.create(:location, :region => @r))
      FactoryGirl.create(:location_machine_xref, :location => FactoryGirl.create(:location, :region => @r))
      FactoryGirl.create(:location_machine_xref, :location => FactoryGirl.create(:location, :region => @r))

      FactoryGirl.create(:location_machine_xref, :location => FactoryGirl.create(:location, :region => @other_region))

      @r.machines_count.should == 4
    end
  end

  describe '#all_admin_email_addresses' do
    it 'should return a default email address if no users are in region' do
      @r.all_admin_email_addresses.should == [ 'email_not_found@noemailfound.noemail' ]
    end
    it 'should return all admin email addresses' do
      FactoryGirl.create(:user, :region => @r, :email => 'not@primary.com')
      FactoryGirl.create(:user, :region => @r, :email => 'is@primary.com', :is_primary_email_contact => 1)

      @r.all_admin_email_addresses.should == [ 'not@primary.com', 'is@primary.com' ]
    end
  end

  describe '#available_search_sections' do
    it 'should not return zone as a search section if the region has no zones' do
      @r.available_search_sections.should == "['city', 'location', 'machine', 'type']"

      FactoryGirl.create(:location, :region => @r, :name => 'Cleo', :zone => FactoryGirl.create(:zone, :region => @r, :name => 'Alberta'))

      Region.find(@r.id).available_search_sections.should == "['city', 'location', 'machine', 'type', 'zone']"
    end

    it 'should not return operator as a search section if the region has no operators' do
      @r.available_search_sections.should == "['city', 'location', 'machine', 'type']"

      FactoryGirl.create(:location, :region => @r, :name => 'Cleo', :operator => FactoryGirl.create(:operator, :name => 'Quarter Bean', :region => @r))

      Region.find(@r.id).available_search_sections.should == "['city', 'location', 'machine', 'type', 'operator']"
    end

    it 'should display all search sections when an operator and zone are present' do
      FactoryGirl.create(:location, :region => @r, :name => 'Cleo', :zone => FactoryGirl.create(:zone, :region => @r, :name => 'Alberta'))
      FactoryGirl.create(:location, :region => @r, :name => 'Cleo', :operator => FactoryGirl.create(:operator, :name => 'Quarter Bean', :region => @r))

      Region.find(@r.id).available_search_sections.should == "['city', 'location', 'machine', 'type', 'operator', 'zone']"
    end
  end
end
