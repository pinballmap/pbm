require 'spec_helper'

describe PagesController do
  before(:each) do
    ApplicationController.any_instance.stub(:set_current_user).and_return(nil)

    region = FactoryGirl.create(:region, :name => 'portland', :full_name => 'Portland')
    @location = FactoryGirl.create(:location, :region => region)
    FactoryGirl.create(:user, :email => 'foo@bar.com', :region => region)
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
end
