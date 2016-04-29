require 'spec_helper'

describe PagesController, type: :controller do
  before(:each) do
    expect_any_instance_of(ApplicationController).to receive(:set_current_user).and_return(nil)

    @region = FactoryGirl.create(:region, name: 'portland', full_name: 'Portland')
    @location = FactoryGirl.create(:location, region: @region)

    FactoryGirl.create(:user, email: 'foo@bar.com', region: @region)
    FactoryGirl.create(:user, email: 'super_admin@bar.com', region: nil, is_super_admin: 1)
  end

  describe '#home - twitter' do
    it 'should return no tweets without env variables set' do
      get 'home'

      expect(assigns(:tweets)).to eq([])
    end

    it 'should error on invalid ENV data' do
      stub_const('ENV', 'TWITTER_CONSUMER_KEY' => '1',  'TWITTER_CONSUMER_SECRET' => '1', 'TWITTER_OAUTH_TOKEN_SECRET' => '1', 'TWITTER_OAUTH_TOKEN' => '1')

      get 'home'

      expect(assigns(:tweets)).to eq([])
    end

    it 'should return no tweets with env variables set, because i am stubbing things out' do
      stub_const('ENV', 'TWITTER_CONSUMER_KEY' => '1',  'TWITTER_CONSUMER_SECRET' => '1', 'TWITTER_OAUTH_TOKEN_SECRET' => '1', 'TWITTER_OAUTH_TOKEN' => '1')
      expect(Twitter::REST::Client).to receive(:new).and_return(Twitter::REST::Client)
      expect(Twitter::REST::Client).to receive(:user_timeline).and_return('tweet' => 'twoot')

      get 'home'

      expect(assigns(:tweets)).to eq('tweet' => 'twoot')
    end
  end

  describe '#links' do
    it 'should redirect you to the about page' do
      get 'links', region: 'portland'
      expect(response).to redirect_to about_path
    end
  end

  describe '#contact' do
    it 'should redirect you to the about page' do
      get 'contact', region: 'portland'
      expect(response).to redirect_to about_path
    end
  end

  describe '#robots' do
    it 'renders public/robots.txt' do
      get 'robots', region: 'portland'
      expect(response.body).to eq(<<HERE)
# See http://www.robotstxt.org/wc/norobots.html for documentation on how to use the robots.txt file\n#\n# To ban all spiders from the entire site uncomment the next two lines:\n# User-Agent: *\n# Disallow: /
HERE
    end
  end

  describe 'contact_sent' do
    it 'should send an email if the body is not blank' do
      logout

      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          to: ['foo@bar.com'],
          bcc: ['super_admin@bar.com'],
          from: 'admin@pinballmap.com',
          subject: 'PBM - Message from the Portland region',
          body: "Their Name: foo\n\nTheir Email: bar\n\nMessage: baz\n\n\n"
        )
      end

      post 'contact_sent', region: 'portland', contact_name: 'foo', contact_email: 'bar', contact_msg: 'baz'
      expect(Region.find(@region.id).user_submissions.count).to eq(1)
      submission = Region.find(@region.id).user_submissions.first
      expect(submission.submission_type).to eq(UserSubmission::CONTACT_US_TYPE)
      expect(submission.submission).to eq("Their Name: foo\n\nTheir Email: bar\n\nMessage: baz\n\n\n")
    end

    it 'should include user info if you are logged in' do
      user = FactoryGirl.create(:user, username: 'ssw', email: 'yeah@ok.com')
      login(user)

      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          to: ['foo@bar.com'],
          bcc: ['super_admin@bar.com'],
          from: 'admin@pinballmap.com',
          subject: 'PBM - Message from the Portland region',
          body: "Their Name: foo\n\nTheir Email: bar\n\nMessage: baz\n\nUsername: ssw\n\nSite Email: yeah@ok.com\n"
        )
      end

      post 'contact_sent', region: 'portland', contact_name: 'foo', contact_email: 'bar', contact_msg: 'baz'
      submission = Region.find(@region.id).user_submissions.first
      expect(submission.user).to eq(user)
      expect(submission.submission).to eq("Their Name: foo\n\nTheir Email: bar\n\nMessage: baz\n\nUsername: ssw\n\nSite Email: yeah@ok.com\n")
    end

    it 'email should notify if it was sent from the staging server' do
      @request.host = 'pinballmapstaging.herokuapp.com'

      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          subject: '(STAGING) PBM - Message from the Portland region'
        )
      end

      post 'contact_sent', region: 'portland', contact_name: 'foo', contact_email: 'bar', contact_msg: 'baz'
    end

    it 'should not send an email if the body is blank' do
      expect(Pony).to_not receive(:mail)

      post 'contact_sent', region: 'portland', contact_name: 'foo', contact_email: 'bar', contact_msg: nil
    end

    it 'should flash an error message if captcha fails' do
      expect(controller).to receive(:verify_recaptcha).and_return(nil)

      expect(Pony).to_not receive(:mail)

      post 'contact_sent', region: 'portland', contact_name: 'foo', contact_email: 'bar', contact_msg: 'baz'

      expect(request.flash[:alert]).to eq('Your captcha entering skills have failed you. Please go back and try again.')
    end
  end

  describe 'submitted_new_location' do
    it 'should send an email' do
      logout

      body = <<HERE
(A new pinball spot has been submitted for your region! Please verify the address on http://maps.google.com and then paste that Google Maps address into http://pinballmap.com/admin. Thanks!)\n
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
(entered from 0.0.0.0 via Rails Testing)\n
HERE

      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          to: ['foo@bar.com'],
          bcc: ['super_admin@bar.com'],
          from: 'admin@pinballmap.com',
          subject: 'PBM - New location suggested for the portland pinball map',
          body: body
        )
      end

      post 'submitted_new_location', region: 'portland', location_name: 'name', location_street: 'street', location_city: 'city', location_state: 'state', location_zip: 'zip', location_phone: 'phone', location_website: 'website', location_operator: 'operator', location_machines: 'machines', submitter_name: 'subname', submitter_email: 'subemail'

      expect(@region.user_submissions.count).to eq(1)
      submission = @region.user_submissions.first
      expect(submission.submission_type).to eq(UserSubmission::SUGGEST_LOCATION_TYPE)
      expect(submission.submission).to eq(body)
    end

    it 'should send an email - includes user info if available' do
      login(FactoryGirl.create(:user, username: 'ssw', email: 'yeah@ok.com'))

      body = <<HERE
(A new pinball spot has been submitted for your region! Please verify the address on http://maps.google.com and then paste that Google Maps address into http://pinballmap.com/admin. Thanks!)\n
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
(entered from 0.0.0.0 via Rails Testing by ssw (yeah@ok.com))\n
HERE
      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          to: ['foo@bar.com'],
          bcc: ['super_admin@bar.com'],
          from: 'admin@pinballmap.com',
          subject: 'PBM - New location suggested for the portland pinball map',
          body: body
        )
      end

      post 'submitted_new_location', region: 'portland', location_name: 'name', location_street: 'street', location_city: 'city', location_state: 'state', location_zip: 'zip', location_phone: 'phone', location_website: 'website', location_operator: 'operator', location_machines: 'machines', submitter_name: 'subname', submitter_email: 'subemail'
    end

    it 'should send an email - notifies if sent from the staging server' do
      @request.host = 'pinballmapstaging.herokuapp.com'

      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          subject: '(STAGING) PBM - New location suggested for the portland pinball map'
        )
      end

      post 'submitted_new_location', region: 'portland', location_name: 'name', location_street: 'street', location_city: 'city', location_state: 'state', location_zip: 'zip', location_phone: 'phone', location_website: 'website', location_operator: 'operator', location_machines: 'machines', submitter_name: 'subname', submitter_email: 'subemail'
    end

    it 'should not send an email with http:// in location_machines name' do
      expect(Pony).to_not receive(:mail)

      post 'submitted_new_location', region: 'portland', location_name: 'name', location_street: 'street', location_city: 'city', location_state: 'state', location_zip: 'zip', location_phone: 'phone', location_website: 'website', location_operator: 'operator', location_machines: 'http://machines', submitter_name: 'subname', submitter_email: 'subemail'
    end

    it 'should flash an error message if captcha fails' do
      expect(controller).to receive(:verify_recaptcha).and_return(nil)

      expect(Pony).to_not receive(:mail)

      post 'submitted_new_location', region: 'portland', location_name: 'name', location_street: 'street', location_city: 'city', location_state: 'state', location_zip: 'zip', location_phone: 'phone', location_website: 'website', location_operator: 'operator', location_machines: 'cool machine', submitter_name: 'subname', submitter_email: 'subemail'

      expect(request.flash[:alert]).to eq('Your captcha entering skills have failed you. Please go back and try again.')
    end
  end
end
