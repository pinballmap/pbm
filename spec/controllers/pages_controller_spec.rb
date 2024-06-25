require 'spec_helper'

describe PagesController, type: :controller do
  before(:each) do
    @region = FactoryBot.create(:region, name: 'portland', full_name: 'Portland')
    @location = FactoryBot.create(:location, region: @region)

    FactoryBot.create(:user, email: 'foo@bar.com', region: @region)
    FactoryBot.create(:user, email: 'super_admin@bar.com', region: nil, is_super_admin: 1)
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

  describe 'contact_sent' do
    before(:each) do
      @user = FactoryBot.create(:user, username: 'ssw', email: 'yeah@ok.com')
      ActionMailer::Base.perform_deliveries = true
      ActionMailer::Base.deliveries = []
    end
    after(:each) do
      ActionMailer::Base.deliveries.clear
    end
    it 'should send an email if the body is not blank' do
      logout

      expect do
        post 'contact_sent', params: { region: 'portland', contact_name: 'foo', contact_email: 'bar', contact_msg: 'baz', security_test: 'pinball' }
        email = ActionMailer::Base.deliveries.last
        expect(email.subject).to eq('Pinball Map - Message (Portland)')
        expect(email.from).to eq(['admin@pinballmap.com'])
        expect(email.to).to eq(['foo@bar.com'])
        expect(email.cc).to eq(['super_admin@bar.com'])
        expect(email.body).to have_content('Name: foo')
        expect(email.body).to have_content('Email: bar')
        expect(email.body).to have_content('baz')
        expect(email.body).to have_content('(entered from 0.0.0.0 via  Rails Testing)')

        expect(@region.reload.user_submissions.count).to eq(1)
        submission = @region.user_submissions.first
        expect(submission.submission_type).to eq(UserSubmission::CONTACT_US_TYPE)
        expect(submission.submission).to eq('Their Name: foo Their Email: bar Message: baz Username:  Site Email:  (entered from 0.0.0.0 via  Rails Testing)')
      end.to change { ActionMailer::Base.deliveries.size }.by(1)
    end

    it 'should include user info if you are logged in' do
      login(@user)

      expect do
        post 'contact_sent', params: { region: 'portland', contact_msg: 'baz' }
        email = ActionMailer::Base.deliveries.last
        expect(email.subject).to eq('Pinball Map - Message (Portland)')
        expect(email.from).to eq(['admin@pinballmap.com'])
        expect(email.to).to eq(['foo@bar.com'])
        expect(email.cc).to eq(['super_admin@bar.com'])
        expect(email.body).to have_content('Username: ssw')
        expect(email.body).to have_content('Email: yeah@ok.com')
        expect(email.body).to have_content('baz')
        expect(email.body).to have_content('(entered from 0.0.0.0 via  Rails Testing)')
        submission = @region.reload.user_submissions.first
        expect(submission.user).to eq(@user)
        expect(submission.submission).to eq('Their Name:  Their Email:  Message: baz Username: ssw Site Email: yeah@ok.com (entered from 0.0.0.0 via  Rails Testing)')
      end.to change { ActionMailer::Base.deliveries.size }.by(1)
    end

    it 'email should notify if it was sent from the staging server' do
      @request.host = 'pbmstaging.com'

      expect do
        post 'contact_sent', params: { region: 'portland', contact_name: 'foo', contact_email: 'bar', contact_msg: 'baz', security_test: 'pinball' }
        email = ActionMailer::Base.deliveries.last
        expect(email.subject).to eq('(STAGING) Pinball Map - Message (Portland)')
      end.to change { ActionMailer::Base.deliveries.size }.by(1)
    end

    it 'should not send an email if the body is blank' do
      expect(ActionMailer::Base.deliveries.count).to eq(0)

      post 'contact_sent', params: { region: 'portland', contact_name: 'foo', contact_email: 'bar', contact_msg: nil, security_test: 'pinball' }
    end

    it 'should not send an email if the email is blank when logged out' do
      logout

      expect(ActionMailer::Base.deliveries.count).to eq(0)

      post 'contact_sent', params: { region: 'portland', contact_name: 'foo', contact_email: nil, contact_msg: 'hello', security_test: 'pinball' }
    end

    it 'should send an email if the email is blank when logged in' do
      login(@user)

      expect do
        post 'contact_sent', params: { region: 'portland', contact_name: 'foo', contact_email: nil, contact_msg: 'hello', security_test: 'pinball' }
      end.to change { ActionMailer::Base.deliveries.size }.by(1)
    end

    it 'should not send an email if the body contains a spam keyword' do
      expect(ActionMailer::Base.deliveries.count).to eq(0)

      post 'contact_sent', params: { region: 'portland', contact_name: 'foo', contact_email: 'bar', contact_msg: 'vape', security_test: 'pinball' }
    end

    it 'should flash an error message if security test fails' do
      logout

      expect(ActionMailer::Base.deliveries.count).to eq(0)

      post 'contact_sent', params: { region: 'portland', contact_name: 'foo', contact_email: 'bar', contact_msg: 'baz', security_test: 'dunno' }
      expect(request.flash[:alert]).to eq('You failed the security test. Please go back and try again.')
    end
  end

  describe 'suggest_new_location' do
    it 'works with a region' do
      post 'suggest_new_location', params: { region: 'portland' }

      expect(assigns(:states)).to eq(['', 'OR'])
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
      before(:each) do
        ActionMailer::Base.perform_deliveries = true
        ActionMailer::Base.deliveries = []
      end
      after(:each) do
        ActionMailer::Base.deliveries.clear
      end
      it 'should send an email' do
        FactoryBot.create(:location_type, name: 'type')
        FactoryBot.create(:operator, name: 'operator')
        FactoryBot.create(:zone, name: 'zone')
        FactoryBot.create(:machine, name: 'Jolene (Pro)', manufacturer: 'Burrito', year: '1995', id: 20)

        logout

        expect do
          post 'submitted_new_location', params: { region: region, location_name: 'name', location_street: 'street', location_city: 'city', location_state: 'state', location_zip: 'zip', location_country: 'country', location_phone: 'phone', location_website: 'website', location_zone: 'zone', location_type: 'type', location_operator: 'operator', location_comments: 'comments', location_machines_ids: [20], submitter_name: 'subname', submitter_email: 'subemail' }

          email = ActionMailer::Base.deliveries.last
          expect(email.to).to eq(region.nil? ? ['super_admin@bar.com'] : ['foo@bar.com'])
          expect(email.from).to eq(['admin@pinballmap.com'])
          expect(email.subject).to eq("Pinball Map - New location suggested#{region.nil? ? '' : ' (' + @region.full_name + ')'}")
          expect(email.body).to have_content('Dear Admin: You can approve this location with the click of a button! In the Suggested Locations section, click the "(i)", and then the big "APPROVE LOCATION" button at the top.')
          expect(email.body).to have_content('Location Name: name')
          expect(email.body).to have_content('Machines: Jolene (Pro) (Burrito, 1995)')
          expect(email.body).to have_content('Street: street')

          expect(region.nil? ? UserSubmission.count : @region.user_submissions.count).to eq(1)
          submission = region.nil? ? UserSubmission.first : @region.user_submissions.first
          expect(submission.submission_type).to eq(UserSubmission::SUGGEST_LOCATION_TYPE)
          expect(submission.submission).to eq('Location Name: name Street: street City: city State: state Zip: zip Country: country Phone: phone Website: website Type: type Operator: operator Zone: zone Comments: comments Machines: Jolene (Pro) (Burrito, 1995),  (entered from 0.0.0.0 via  Rails Testing)')
        end.to change { ActionMailer::Base.deliveries.size }.by(1)
      end

      it 'should send an email - includes user info if available' do
        FactoryBot.create(:location_type, name: 'type')
        FactoryBot.create(:operator, name: 'operator')
        FactoryBot.create(:machine, name: 'Jolene (Pro)', manufacturer: 'Burrito', year: '1995', id: 20)

        login(FactoryBot.create(:user, username: 'ssw', email: 'yeah@ok.com'))

        expect do
          post 'submitted_new_location', params: { region: region, location_name: 'name', location_street: 'street', location_city: 'city', location_state: 'state', location_zip: 'zip', location_country: 'country', location_phone: 'phone', location_website: 'website', location_type: 'type', location_operator: 'operator', location_comments: 'comments', location_machines_ids: [20], submitter_name: 'subname', submitter_email: 'subemail' }

          email = ActionMailer::Base.deliveries.last
          expect(email.to).to eq(region.nil? ? ['super_admin@bar.com'] : ['foo@bar.com'])
          expect(email.from).to eq(['admin@pinballmap.com'])
          expect(email.subject).to eq("Pinball Map - New location suggested#{region.nil? ? '' : ' (' + @region.full_name + ')'}")
          expect(email.body).to have_content('Location Name: name')

          expect(region.nil? ? UserSubmission.count : @region.user_submissions.count).to eq(1)
          submission = region.nil? ? UserSubmission.first : @region.user_submissions.first
          expect(submission.submission_type).to eq(UserSubmission::SUGGEST_LOCATION_TYPE)
          expect(submission.submission).to have_content('Rails Testing by ssw (yeah@ok.com))')
        end.to change { ActionMailer::Base.deliveries.size }.by(1)
      end

      it 'should send an email - notifies if sent from the staging server' do
        FactoryBot.create(:machine, name: 'Jolene (Pro)', manufacturer: 'Burrito', year: '1995', id: 20)
        @request.host = 'pbmstaging.com'

        expect do
          post 'submitted_new_location', params: { region: region, location_name: 'name', location_street: 'street', location_city: 'city', location_state: 'state', location_zip: 'zip', location_phone: 'phone', location_website: 'website', location_type: 'type', location_operator: 'operator', location_comments: 'comments', location_machines_ids: [20], submitter_name: 'subname', submitter_email: 'subemail' }

          email = ActionMailer::Base.deliveries.last
          expect(email.subject).to eq("(STAGING) Pinball Map - New location suggested#{region.nil? ? '' : ' (' + @region.full_name + ')'}")
        end.to change { ActionMailer::Base.deliveries.size }.by(1)
      end

      it 'should create a suggested location object' do
        location_type = FactoryBot.create(:location_type, name: 'type')
        operator = FactoryBot.create(:operator, name: 'operator')
        zone = FactoryBot.create(:zone, name: 'zone')
        FactoryBot.create(:machine, name: 'Jolene (Pro)', manufacturer: 'Burrito', year: '1995', id: 20)

        post 'submitted_new_location', params: { region: region, location_name: 'name', location_street: 'street', location_city: 'city', location_state: 'state', location_zip: 'zip', location_country: 'country', location_phone: 'phone', location_website: 'website', location_type: 'type', location_zone: 'zone', location_operator: 'operator', location_comments: 'comments', location_machines_ids: [20], submitter_name: 'subname', submitter_email: 'subemail' }

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
        expect(sl.machines).to eq("[\"20\"]")
        expect(sl.user_inputted_address).to eq('street, city, state, zip')
      end
    end
  end
end
