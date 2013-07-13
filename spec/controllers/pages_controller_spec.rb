require 'spec_helper'

describe PagesController do
  before(:each) do
    ApplicationController.any_instance.stub(:set_current_user).and_return(nil)

    region = FactoryGirl.create(:region, :name => 'portland', :full_name => 'Portland')
    @location = FactoryGirl.create(:location, :region => region)

    FactoryGirl.create(:user, :email => 'foo@bar.com', :region => region)
    FactoryGirl.create(:user, :email => 'super_admin@bar.com', :region => nil, :is_super_admin => 1)
  end

  describe 'contact_sent' do
    it 'should send an email if the body is not blank' do
      Pony.should_receive(:mail) do |mail|
        mail.should == {
          :to => ["foo@bar.com"],
          :from =>"admin@pinballmap.com",
          :subject => "Message from Portland pinball map",
          :body => "foo\nbar\nbaz",
        }
      end

      post 'contact_sent', :region => 'portland', :contact_name => 'foo', :contact_email => 'bar', :contact_msg => 'baz'
    end
    it 'should not send an email if the body is blank' do
      Pony.should_not_receive(:mail) do |mail|
        mail.should == {
          :to => ["foo@bar.com"],
          :from =>"admin@pinballmap.com",
          :subject => "Message from Portland pinball map",
          :body => "foo\nbar\nbaz",
        }
      end

      post 'contact_sent', :region => 'portland', :contact_name => 'foo', :contact_email => 'bar', :contact_msg => nil
    end
  end
  describe 'submitted_new_location' do
    it 'should send an email' do
      Pony.should_receive(:mail) do |mail|
        mail.should == {
          :to => ["foo@bar.com", "super_admin@bar.com"],
          :from =>"admin@pinballmap.com",
          :subject => "Someone suggested a new location for portland",
          :body => "
          Location Name: name\n
          Street: street\n
          City: city\n
          State: state\n
          Zip: zip\n
          Phone: phone\n
          Website: website\n
          Operator: operator\n
          Machines: machines\n
          Their Name: subname\n
          Their Email: subemail\n
        "
        }
      end

      post 'submitted_new_location', :region => 'portland', :location_name => 'name', :location_street => 'street', :location_city => 'city', :location_state => 'state', :location_zip => 'zip', :location_phone => 'phone', :location_website => 'website', :location_operator => 'operator', :location_machines => 'machines', :submitter_name => 'subname', :submitter_email => 'subemail'
    end
  end
end
