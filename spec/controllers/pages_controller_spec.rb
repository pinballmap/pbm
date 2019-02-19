require 'spec_helper'

describe PagesController, type: :controller do
  before(:each) do
    @region = FactoryBot.create(:region, name: 'portland', full_name: 'Portland')
    @location = FactoryBot.create(:location, region: @region)

    FactoryBot.create(:user, email: 'foo@bar.com', region: @region)
    FactoryBot.create(:user, email: 'super_admin@bar.com', region: nil, is_super_admin: 1)
  end

  describe '#home - twitter' do
    it 'should return no tweets without env variables set' do
      get 'home'

      expect(assigns(:tweets)).to eq([])
    end

    it 'should error on invalid ENV data' do
      stub_const('ENV', 'TWITTER_CONSUMER_KEY' => '1', 'TWITTER_CONSUMER_SECRET' => '1', 'TWITTER_OAUTH_TOKEN_SECRET' => '1', 'TWITTER_OAUTH_TOKEN' => '1')

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
      get 'links', params: { region: 'portland' }
      expect(response).to redirect_to about_path
    end
  end

  describe '#contact' do
    it 'should redirect you to the about page' do
      get 'contact', params: { region: 'portland' }
      expect(response).to redirect_to about_path
    end
  end

  describe '#robots' do
    it 'renders public/robots.txt' do
      get 'robots', params: { region: 'portland' }
      expect(response.body).to eq(<<HERE)
# See http://www.robotstxt.org/wc/norobots.html for documentation on how to use the robots.txt file
#
# To ban all spiders from the entire site uncomment the next two lines:
User-Agent: *
Disallow: */locations

User-agent: SemrushBot
Disallow: /
HERE
    end
  end

  describe 'contact_sent' do
    it 'should send an email if the body is not blank' do
      logout

      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          to: ['foo@bar.com'],
          cc: ['super_admin@bar.com'],
          from: 'admin@pinballmap.com',
          subject: 'PBM - Message from the Portland region',
          body: "Their Name: foo\n\nTheir Email: bar\n\nMessage: baz\n\n\n\n(entered from 0.0.0.0 via Rails Testing)\n\n"
        )
      end

      post 'contact_sent', params: { region: 'portland', contact_name: 'foo', contact_email: 'bar', contact_msg: 'baz' }
      expect(@region.reload.user_submissions.count).to eq(1)
      submission = @region.user_submissions.first
      expect(submission.submission_type).to eq(UserSubmission::CONTACT_US_TYPE)
      expect(submission.submission).to eq("Their Name: foo\n\nTheir Email: bar\n\nMessage: baz\n\n\n\n(entered from 0.0.0.0 via Rails Testing)\n\n")
    end

    it 'should include user info if you are logged in' do
      user = FactoryBot.create(:user, username: 'ssw', email: 'yeah@ok.com')
      login(user)

      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          to: ['foo@bar.com'],
          cc: ['super_admin@bar.com'],
          from: 'admin@pinballmap.com',
          subject: 'PBM - Message from the Portland region',
          body: "Their Name: foo\n\nTheir Email: bar\n\nMessage: baz\n\nUsername: ssw\n\nSite Email: yeah@ok.com\n\n(entered from 0.0.0.0 via Rails Testing)\n\n"
        )
      end

      post 'contact_sent', params: { region: 'portland', contact_name: 'foo', contact_email: 'bar', contact_msg: 'baz' }
      submission = @region.reload.user_submissions.first
      expect(submission.user).to eq(user)
      expect(submission.submission).to eq("Their Name: foo\n\nTheir Email: bar\n\nMessage: baz\n\nUsername: ssw\n\nSite Email: yeah@ok.com\n\n(entered from 0.0.0.0 via Rails Testing)\n\n")
    end

    it 'email should notify if it was sent from the staging server' do
      @request.host = 'pinballmapstaging.herokuapp.com'

      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          subject: '(STAGING) PBM - Message from the Portland region'
        )
      end

      post 'contact_sent', params: { region: 'portland', contact_name: 'foo', contact_email: 'bar', contact_msg: 'baz' }
    end

    it 'should not send an email if the body is blank' do
      expect(Pony).to_not receive(:mail)

      post 'contact_sent', params: { region: 'portland', contact_name: 'foo', contact_email: 'bar', contact_msg: nil }
    end

    it 'should flash an error message if captcha fails' do
      logout
      expect(controller).to receive(:verify_recaptcha).and_return(nil)

      expect(Pony).to_not receive(:mail)

      post 'contact_sent', params: { region: 'portland', contact_name: 'foo', contact_email: 'bar', contact_msg: 'baz' }

      expect(request.flash[:alert]).to eq('Your captcha entering skills have failed you. Please go back and try again.')
    end
  end

  describe 'suggest_new_location' do
    it 'works with a region' do
      post 'suggest_new_location', params: { region: 'portland' }

      expect(assigns(:states)).to eq(['','OR'])
      expect(assigns(:operators)).to eq([''])
      expect(assigns(:zones)).to eq([''])
      expect(assigns(:location_types)).to eq(['', 'Test Location Type'])
    end

    it 'works without a region' do
      post 'suggest_new_location', params: { region: nil }

      expect(assigns(:states)).to eq([])
      expect(assigns(:operators)).to eq([])
      expect(assigns(:zones)).to eq([])
      expect(assigns(:location_types)).to eq(['', 'Test Location Type'])
    end
  end

  ['portland', nil].each do |region|
    describe 'submitted_new_location' do
      it 'should send an email' do
        FactoryBot.create(:location_type, name: 'type')
        FactoryBot.create(:operator, name: 'operator')
        FactoryBot.create(:zone, name: 'zone')

        logout

        body = <<HERE
    Dear Admin: A new pinball spot has been submitted for your region! Please verify/fix the address using https://maps.google.com and then "Promote" the location to the map via http://test.host/admin/suggested_location. If any fields are missing, like Location Type, please fill them in! Thanks!!\n
Location Name: name\n
Street: street\n
City: city\n
State: state\n
Zip: zip\n
Country: country\n
Phone: phone\n
Website: website\n
Type: type\n
Operator: operator\n
Zone: zone\n
Comments: comments\n
Machines: machines\n
(entered from 0.0.0.0 via Rails Testing)\n
HERE

        expect(Pony).to receive(:mail) do |mail|
          expect(mail).to include(
            to: region.nil? ? ['super_admin@bar.com'] : ['foo@bar.com'],
            bcc: ['super_admin@bar.com'],
            from: 'admin@pinballmap.com',
            subject: "PBM - New location suggested for the #{region.nil? ? 'REGIONLESS' : region} pinball map",
            body: body
          )
        end

        post 'submitted_new_location', params: { region: region, location_name: 'name', location_street: 'street', location_city: 'city', location_state: 'state', location_zip: 'zip', location_country: 'country', location_phone: 'phone', location_website: 'website', location_zone: 'zone', location_type: 'type', location_operator: 'operator', location_comments: 'comments', location_machines: 'machines', submitter_name: 'subname', submitter_email: 'subemail' }

        expect(region.nil? ? UserSubmission.count : @region.user_submissions.count).to eq(1)
        submission = region.nil? ? UserSubmission.first : @region.user_submissions.first
        expect(submission.submission_type).to eq(UserSubmission::SUGGEST_LOCATION_TYPE)
        expect(submission.submission).to eq(body)
      end

      it 'should send an email - includes user info if available' do
        FactoryBot.create(:location_type, name: 'type')
        FactoryBot.create(:operator, name: 'operator')

        login(FactoryBot.create(:user, username: 'ssw', email: 'yeah@ok.com'))

        body = <<HERE
    Dear Admin: A new pinball spot has been submitted for your region! Please verify/fix the address using https://maps.google.com and then "Promote" the location to the map via http://test.host/admin/suggested_location. If any fields are missing, like Location Type, please fill them in! Thanks!!\n
Location Name: name\n
Street: street\n
City: city\n
State: state\n
Zip: zip\n
Country: country\n
Phone: phone\n
Website: website\n
Type: type\n
Operator: operator\n
Zone: \n
Comments: comments\n
Machines: machines\n
(entered from 0.0.0.0 via Rails Testing by ssw (yeah@ok.com))\n
HERE
        expect(Pony).to receive(:mail) do |mail|
          expect(mail).to include(
            to: region ? ['foo@bar.com'] : ['super_admin@bar.com'],
            bcc: ['super_admin@bar.com'],
            from: 'admin@pinballmap.com',
            subject: "PBM - New location suggested for the #{region.nil? ? 'REGIONLESS' : region} pinball map",
            body: body
          )
        end

        post 'submitted_new_location', params: { region: region, location_name: 'name', location_street: 'street', location_city: 'city', location_state: 'state', location_zip: 'zip', location_country: 'country', location_phone: 'phone', location_website: 'website', location_type: 'type', location_operator: 'operator', location_comments: 'comments', location_machines: 'machines', submitter_name: 'subname', submitter_email: 'subemail' }
      end

      it 'should send an email - notifies if sent from the staging server' do
        @request.host = 'pinballmapstaging.herokuapp.com'

        expect(Pony).to receive(:mail) do |mail|
          expect(mail).to include(
            subject: "(STAGING) PBM - New location suggested for the #{region.nil? ? 'REGIONLESS' : region} pinball map"
          )
        end

        post 'submitted_new_location', params: { region: region, location_name: 'name', location_street: 'street', location_city: 'city', location_state: 'state', location_zip: 'zip', location_phone: 'phone', location_website: 'website', location_type: 'type', location_operator: 'operator', location_comments: 'comments', location_machines: 'machines', submitter_name: 'subname', submitter_email: 'subemail' }
      end

      it 'should create a suggested location object' do
        location_type = FactoryBot.create(:location_type, name: 'type')
        operator = FactoryBot.create(:operator, name: 'operator')
        zone = FactoryBot.create(:zone, name: 'zone')

        post 'submitted_new_location', params: { region: region, location_name: 'name', location_street: 'street', location_city: 'city', location_state: 'state', location_zip: 'zip', location_country: 'country', location_phone: 'phone', location_website: 'website', location_type: 'type', location_zone: 'zone', location_operator: 'operator', location_comments: 'comments', location_machines: 'machines', submitter_name: 'subname', submitter_email: 'subemail' }

        expect(SuggestedLocation.all.size).to eq(1)

        sl = SuggestedLocation.first
        expect(sl.name).to eq('name')
        expect(sl.region).to eq(region.nil? ? nil : @region)
        expect(sl.street).to eq('street')
        expect(sl.city).to eq('city')
        expect(sl.state).to eq('state')
        expect(sl.zip).to eq('zip')
        expect(sl.country).to eq('country')
        expect(sl.phone).to eq('phone')
        expect(sl.website).to eq('website')
        expect(sl.location_type).to eq(location_type)
        expect(sl.zone).to eq(zone)
        expect(sl.operator).to eq(operator)
        expect(sl.comments).to eq('comments')
        expect(sl.machines).to eq('machines')
        expect(sl.user_inputted_address).to eq('street, city, state, zip')
      end
    end
  end
end
