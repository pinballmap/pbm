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
    it 'redirects to the about page when a region is present' do
      get 'contact', params: { region: 'portland' }
      expect(response).to redirect_to about_path
    end

    it 'renders the global contact page when no region is present' do
      get 'contact'
      expect(response).to be_successful
    end
  end

  describe 'contact_sent' do
    before(:each) do
      @user = FactoryBot.create(:user, username: 'ssw', email: 'yeah@ok.com')
    end
    it 'should send an email if the body is not blank' do
      logout

      expect { post 'contact_sent', params: { region: 'portland', contact_name: 'foo', contact_email: 'bar', contact_msg: 'baz', security_question: 'pinball' } }.to have_enqueued_job(ActionMailer::MailDeliveryJob).with('AdminMailer', 'send_admin_notification', 'deliver_now', { params: { name: 'foo', email: 'bar', message: 'baz', user_name: nil, user_email: nil, to_users: 'admin@pinballmap.com', cc_users: [ 'super_admin@bar.com', 'foo@bar.com' ], subject: 'Pinball Map - Message (Portland) from foo', remote_ip: '0.0.0.0', headers: nil, user_agent: 'Rails Testing' }, args: [] })
    end

    it 'should include user info if you are logged in' do
      login(@user)

      expect { post 'contact_sent', params: { region: 'portland', contact_msg: 'baz' } }.to have_enqueued_job(ActionMailer::MailDeliveryJob).with('AdminMailer', 'send_admin_notification', 'deliver_now', { params: { name: nil, email: nil, message: 'baz', user_name: 'ssw', user_email: 'yeah@ok.com', to_users: 'admin@pinballmap.com', cc_users: [ 'super_admin@bar.com', 'foo@bar.com' ], subject: 'Pinball Map - Message (Portland) from ssw', remote_ip: '0.0.0.0', headers: nil, user_agent: 'Rails Testing' }, args: [] })
    end

    it 'email should notify if it was sent from the staging server' do
      @request.host = 'pbmstaging.com'

      expect { post 'contact_sent', params: { region: 'portland', contact_name: 'foo', contact_email: 'bar', contact_msg: 'baz', security_question: 'pinball' } }.to have_enqueued_job(ActionMailer::MailDeliveryJob).with('AdminMailer', 'send_admin_notification', 'deliver_now', { params: { name: 'foo', email: 'bar', message: 'baz', user_name: nil, user_email: nil, to_users: 'admin@pinballmap.com', cc_users: [ 'super_admin@bar.com', 'foo@bar.com' ], subject: '(STAGING) Pinball Map - Message (Portland) from foo', remote_ip: '0.0.0.0', headers: nil, user_agent: 'Rails Testing' }, args: [] })
    end

    it 'should not send an email if the body is blank' do
      expect { post 'contact_sent', params: { region: 'portland', contact_name: 'foo', contact_email: 'bar', contact_msg: nil, security_question: 'pinball' } }.to_not have_enqueued_job
    end

    it 'should not send an email if the email is blank when logged out' do
      logout

      expect { post 'contact_sent', params: { region: 'portland', contact_name: 'foo', contact_email: nil, contact_msg: 'hello', security_question: 'pinball' } }.to_not have_enqueued_job
    end

    it 'should send an email if the email is blank when logged in' do
      login(@user)

      expect { post 'contact_sent', params: { region: 'portland', contact_name: 'foo', contact_email: nil, contact_msg: 'hello', security_question: 'pinball' } }.to have_enqueued_job(ActionMailer::MailDeliveryJob).with('AdminMailer', 'send_admin_notification', 'deliver_now', { params: { name: 'foo', email: nil, message: 'hello', user_name: 'ssw', user_email: 'yeah@ok.com', to_users: 'admin@pinballmap.com', cc_users: [ 'super_admin@bar.com', 'foo@bar.com' ], subject: 'Pinball Map - Message (Portland) from ssw', remote_ip: '0.0.0.0', headers: nil, user_agent: 'Rails Testing' }, args: [] })
    end

    it 'should not send an email if the body contains a spam keyword' do
      expect { post 'contact_sent', params: { region: 'portland', contact_name: 'foo', contact_email: 'bar', contact_msg: 'vape', security_question: 'pinball' } }.to_not have_enqueued_job
    end

    it 'should flash an error message if security test fails' do
      logout

      expect { post 'contact_sent', params: { region: 'portland', contact_name: 'foo', contact_email: 'bar', contact_msg: 'baz', security_question: 'dunno' } }.to_not have_enqueued_job
    end
  end

  describe 'global contact_sent (no region)' do
    before(:each) do
      @user = FactoryBot.create(:user, username: 'ssw', email: 'yeah@ok.com')
    end

    it 'should send an email to super admins only (no regional cc) when logged out' do
      logout

      expect { post 'contact_sent', params: { contact_name: 'foo', contact_email: 'bar', contact_msg: 'baz', security_question: 'pinball' } }.to have_enqueued_job(ActionMailer::MailDeliveryJob).with('AdminMailer', 'send_admin_notification', 'deliver_now', { params: { name: 'foo', email: 'bar', message: 'baz', user_name: nil, user_email: nil, to_users: 'admin@pinballmap.com', cc_users: [ 'super_admin@bar.com' ], subject: 'Pinball Map - Message from foo', remote_ip: '0.0.0.0', headers: nil, user_agent: 'Rails Testing' }, args: [] })
    end

    it 'should send an email to super admins only (no regional cc) when logged in' do
      login(@user)

      expect { post 'contact_sent', params: { contact_msg: 'baz' } }.to have_enqueued_job(ActionMailer::MailDeliveryJob).with('AdminMailer', 'send_admin_notification', 'deliver_now', { params: { name: nil, email: nil, message: 'baz', user_name: 'ssw', user_email: 'yeah@ok.com', to_users: 'admin@pinballmap.com', cc_users: [ 'super_admin@bar.com' ], subject: 'Pinball Map - Message from ssw', remote_ip: '0.0.0.0', headers: nil, user_agent: 'Rails Testing' }, args: [] })
    end

    it 'should not send an email if the body is blank' do
      expect { post 'contact_sent', params: { contact_name: 'foo', contact_email: 'bar', contact_msg: nil, security_question: 'pinball' } }.to_not have_enqueued_job
    end

    it 'should not send an email if the email is blank when logged out' do
      logout

      expect { post 'contact_sent', params: { contact_name: 'foo', contact_email: nil, contact_msg: 'hello', security_question: 'pinball' } }.to_not have_enqueued_job
    end

    it 'should flash an error message if security test fails' do
      logout

      expect { post 'contact_sent', params: { contact_name: 'foo', contact_email: 'bar', contact_msg: 'baz', security_question: 'dunno' } }.to_not have_enqueued_job
    end
  end

  describe 'check_place_id' do
    it 'should not submit suggested location if place_id exists' do
      FactoryBot.create(:location, place_id: 'tgtgtgtgtgtgtg')

      expect { post 'submitted_new_location', params: { location_name: 'name', location_street: 'street', location_city: 'city', location_state: 'state', location_zip: 'zip', location_country: 'country', location_phone: 'phone', location_website: 'website', location_zone: 'zone', location_type: 'type', location_operator: 'operator', location_comments: 'comments', location_machines_ids: [ 20 ], place_id: 'tgtgtgtgtgtgtg', submitter_name: 'subname', submitter_email: 'subemail' } }.to_not have_enqueued_job
    end
  end

  describe '#recent_activity' do
    before(:each) do
      @user = FactoryBot.create(:user, username: 'ssw', email: 'yeah@ok.com')
      @machine = FactoryBot.create(:machine, name: 'Cleo')
    end

    it 'includes locationless scores for the current user' do
      login(@user)
      FactoryBot.create(:user_submission,
        submission_type: 'new_msx',
        user: @user,
        machine: @machine,
        submission: 'ssw added a high score of 5,000 on Cleo',
        location_name: nil,
        region: nil
      )

      get 'recent_activity'

      expect(assigns(:recent_activity).map(&:submission_type)).to include('new_msx')
    end

    it 'does not include locationless scores from other users' do
      login(@user)
      other_user = FactoryBot.create(:user, username: 'other', email: 'other@ok.com')
      FactoryBot.create(:user_submission,
        submission_type: 'new_msx',
        user: other_user,
        machine: @machine,
        submission: 'other added a high score of 5,000 on Cleo',
        location_name: nil,
        region: nil
      )

      get 'recent_activity'

      expect(assigns(:recent_activity)).to be_empty
    end

    it 'includes location-based scores from any user' do
      login(@user)
      FactoryBot.create(:user_submission,
        submission_type: 'new_msx',
        user: @user,
        location: @location,
        machine: @machine,
        location_name: @location.name,
        submission: 'ssw added a high score of 5,000 on Cleo at Test Location Name in Portland'
      )

      get 'recent_activity'

      expect(assigns(:recent_activity).map(&:submission_type)).to include('new_msx')
    end

    it 'does not include locationless scores when logged out' do
      FactoryBot.create(:user_submission,
        submission_type: 'new_msx',
        user: @user,
        machine: @machine,
        submission: 'ssw added a high score of 5,000 on Cleo',
        location_name: nil,
        region: nil
      )

      get 'recent_activity'

      expect(assigns(:recent_activity)).to be_empty
    end

    it 'your_activity filter returns only current user submissions across all types' do
      login(@user)
      other_user = FactoryBot.create(:user, username: 'other', email: 'other@ok.com')
      FactoryBot.create(:user_submission,
        submission_type: 'new_lmx',
        user: @user,
        location: @location,
        location_name: @location.name,
        submission: 'ssw added a machine'
      )
      FactoryBot.create(:user_submission,
        submission_type: 'new_lmx',
        user: other_user,
        location: @location,
        location_name: @location.name,
        submission: 'other added a machine'
      )

      get 'recent_activity', params: { submission_type: [ 'your_activity' ] }

      submissions = assigns(:recent_activity)
      expect(submissions.map(&:user_id).uniq).to eq([ @user.id ])
    end

    it 'your_activity combined with a type filter returns only that type for current user' do
      login(@user)
      other_user = FactoryBot.create(:user, username: 'other', email: 'other@ok.com')
      FactoryBot.create(:user_submission,
        submission_type: 'new_lmx',
        user: @user,
        location: @location,
        location_name: @location.name,
        submission: 'ssw added a machine'
      )
      FactoryBot.create(:user_submission,
        submission_type: 'new_condition',
        user: @user,
        location: @location,
        location_name: @location.name,
        submission: 'ssw left a condition'
      )
      FactoryBot.create(:user_submission,
        submission_type: 'new_lmx',
        user: other_user,
        location: @location,
        location_name: @location.name,
        submission: 'other added a machine'
      )

      get 'recent_activity', params: { submission_type: [ 'your_activity', 'new_lmx' ] }

      submissions = assigns(:recent_activity)
      expect(submissions.map(&:submission_type).uniq).to eq([ 'new_lmx' ])
      expect(submissions.map(&:user_id).uniq).to eq([ @user.id ])
    end

    context 'view rendering' do
      render_views

      it 'pre-checks the your_activity checkbox when submission_type param is present in URL' do
        login(@user)
        get 'recent_activity', params: { submission_type: [ 'your_activity' ] }
        doc = Nokogiri::HTML(response.body)
        expect(doc.at('#filterYourActivity')['checked']).to eq('checked')
      end
    end

    it 'your_activity filter returns empty when logged out' do
      other_user = FactoryBot.create(:user, username: 'other', email: 'other@ok.com')
      FactoryBot.create(:user_submission,
        submission_type: 'new_lmx',
        user: other_user,
        location: @location,
        location_name: @location.name,
        submission: 'other added a machine'
      )

      get 'recent_activity', params: { submission_type: [ 'your_activity' ] }

      expect(assigns(:recent_activity)).to be_empty
    end
  end

  describe 'suggest_new_location' do
    it 'works with a region' do
      post 'suggest_new_location', params: { region: 'portland' }

      expect(assigns(:states)).to eq([ '', 'OR' ])
      expect(assigns(:operators)).to eq([ '' ])
      expect(assigns(:zones)).to eq([ '' ])
      expect(assigns(:location_types)).to eq([ '', 'Test Location Type' ])
    end

    it 'works without a region' do
      post 'suggest_new_location', params: { region: nil }

      expect(assigns(:states)).to eq([])
      expect(assigns(:operators)).to eq([])
      expect(assigns(:zones)).to eq([])
      expect(assigns(:location_types)).to eq([ '', 'Test Location Type' ])
    end
  end

  [ 'portland', nil ].each do |region|
    describe 'submitted_new_location' do
      it 'should send an email' do
        FactoryBot.create(:location_type, name: 'type')
        FactoryBot.create(:operator, name: 'operator')
        FactoryBot.create(:zone, name: 'zone')
        FactoryBot.create(:machine, name: 'Jolene (Pro)', manufacturer: 'Burrito', year: '1995', id: 20)

        logout

        if region == 'portland'
          expect { post 'submitted_new_location', params: { region: region, location_name: 'name', location_street: 'street', location_city: 'city', location_state: 'state', location_zip: 'zip', location_country: 'country', location_phone: 'phone', location_website: 'website', location_zone: 'zone', location_type: 'type', location_operator: 'operator', location_comments: 'comments', location_machines_ids: [ 20 ], place_id: 'tgtgtgtgtgtgtg', submitter_name: 'subname', submitter_email: 'subemail' } }.to_not have_enqueued_job
        else
          expect { post 'submitted_new_location', params: { region: region, location_name: 'name', location_street: 'street', location_city: 'city', location_state: 'state', location_zip: 'zip', location_country: 'country', location_phone: 'phone', location_website: 'website', location_zone: 'zone', location_type: 'type', location_operator: 'operator', location_comments: 'comments', location_machines_ids: [ 20 ], place_id: 'tgtgtgtgtgtgtg', submitter_name: 'subname', submitter_email: 'subemail' } }.to_not have_enqueued_job
        end

        login(FactoryBot.create(:user, username: 'ssw', email: 'yeah@ok.com'))

        if region == 'portland'
          expect { post 'submitted_new_location', params: { region: region, location_name: 'name', location_street: 'street', location_city: 'city', location_state: 'state', location_zip: 'zip', location_country: 'country', location_phone: 'phone', location_website: 'website', location_zone: 'zone', location_type: 'type', location_operator: 'operator', location_comments: 'comments', location_machines_ids: [ 20 ], place_id: 'tgtgtgtgtgtgtg', submitter_name: 'subname', submitter_email: 'subemail' } }.to have_enqueued_job(ActionMailer::MailDeliveryJob).with('AdminMailer', 'send_new_location_notification', 'deliver_now', { params: { to_users: 'admin@pinballmap.com', cc_users: [ 'super_admin@bar.com', 'foo@bar.com' ], subject: 'Pinball Map - New location (Portland) - name', location_name: 'name', location_street: 'street', location_city: 'city', location_state: 'state', location_zip: 'zip', location_country: 'country', location_phone: 'phone', location_website: 'website', location_type: 'type', operator: 'operator', zone: 'zone', location_comments: 'comments', location_machines: 'Jolene (Pro) (Burrito, 1995), ', admin_notes: nil, place_id: 'tgtgtgtgtgtgtg', remote_ip: '0.0.0.0', headers: nil, user_agent: 'Rails Testing', user_info: ' by ssw (yeah@ok.com)', user_email: 'yeah@ok.com' }, args: [] })
        else
          expect { post 'submitted_new_location', params: { region: region, location_name: 'name', location_street: 'street', location_city: 'city', location_state: 'state', location_zip: 'zip', location_country: 'country', location_phone: 'phone', location_website: 'website', location_type: 'type', location_operator: 'operator', location_comments: 'comments', location_machines_ids: [ 20 ], place_id: 'tgtgtgtgtgtgtg', submitter_name: 'subname', submitter_email: 'subemail' } }.to have_enqueued_job(ActionMailer::MailDeliveryJob).with('AdminMailer', 'send_new_location_notification', 'deliver_now', { params: { to_users: 'admin@pinballmap.com', cc_users: [ 'super_admin@bar.com' ], subject: 'Pinball Map - New location - name', location_name: 'name', location_street: 'street', location_city: 'city', location_state: 'state', location_zip: 'zip', location_country: 'country', location_phone: 'phone', location_website: 'website', location_type: 'type', operator: 'operator', zone: '', location_comments: 'comments', location_machines: 'Jolene (Pro) (Burrito, 1995), ', admin_notes: nil, place_id: 'tgtgtgtgtgtgtg', remote_ip: '0.0.0.0', headers: nil, user_agent: 'Rails Testing', user_info: ' by ssw (yeah@ok.com)', user_email: 'yeah@ok.com' }, args: [] })
        end
      end

      it 'should send an email - notifies if sent from the staging server' do
        FactoryBot.create(:machine, name: 'Jolene (Pro)', manufacturer: 'Burrito', year: '1995', id: 20)
        @request.host = 'pbmstaging.com'
        login(FactoryBot.create(:user, username: 'ssw', email: 'yeah@ok.com'))

        if region == 'portland'
          expect { post 'submitted_new_location', params: { region: region, location_name: 'name', location_street: 'street', location_city: 'city', location_state: 'state', location_zip: 'zip', location_phone: 'phone', location_website: 'website', location_comments: 'comments', location_machines_ids: [ 20 ], place_id: 'tgtgtgtgtgtgtg', submitter_name: 'subname', submitter_email: 'subemail' } }.to have_enqueued_job(ActionMailer::MailDeliveryJob).with('AdminMailer', 'send_new_location_notification', 'deliver_now', { params: { to_users: 'admin@pinballmap.com', cc_users: [ 'super_admin@bar.com', 'foo@bar.com' ], subject: '(STAGING) Pinball Map - New location (Portland) - name', location_name: 'name', location_street: 'street', location_city: 'city', location_state: 'state', location_zip: 'zip', location_country: nil, location_phone: 'phone', location_website: 'website', location_type: '', operator: '', zone: '', location_comments: 'comments', location_machines: 'Jolene (Pro) (Burrito, 1995), ', admin_notes: 'No location type, please add', place_id: 'tgtgtgtgtgtgtg', remote_ip: '0.0.0.0', headers: nil, user_agent: 'Rails Testing', user_info: ' by ssw (yeah@ok.com)', user_email: 'yeah@ok.com' }, args: [] })
        else
          expect { post 'submitted_new_location', params: { region: region, location_name: 'name', location_street: 'street', location_city: 'city', location_state: 'state', location_zip: 'zip', location_phone: 'phone', location_website: 'website', location_comments: 'comments', location_machines_ids: [ 20 ], place_id: 'tgtgtgtgtgtgtg', submitter_name: 'subname', submitter_email: 'subemail' } }.to have_enqueued_job(ActionMailer::MailDeliveryJob).with('AdminMailer', 'send_new_location_notification', 'deliver_now', { params: { to_users: 'admin@pinballmap.com', cc_users: [ 'super_admin@bar.com' ], subject: '(STAGING) Pinball Map - New location - name', location_name: 'name', location_street: 'street', location_city: 'city', location_state: 'state', location_zip: 'zip', location_country: nil, location_phone: 'phone', location_website: 'website', location_type: '', operator: '', zone: '', location_comments: 'comments', location_machines: 'Jolene (Pro) (Burrito, 1995), ', admin_notes: 'No location type, please add', place_id: 'tgtgtgtgtgtgtg', remote_ip: '0.0.0.0', headers: nil, user_agent: 'Rails Testing', user_info: ' by ssw (yeah@ok.com)', user_email: 'yeah@ok.com' }, args: [] })
        end
      end

      it 'should create a suggested location object' do
        location_type = FactoryBot.create(:location_type, name: 'type')
        operator = FactoryBot.create(:operator, name: 'operator')
        zone = FactoryBot.create(:zone, name: 'zone')
        FactoryBot.create(:machine, name: 'Jolene (Pro)', manufacturer: 'Burrito', year: '1995', id: 20)
        login(FactoryBot.create(:user, username: 'ssw', email: 'yeah@ok.com'))

        post 'submitted_new_location', params: { region: region, location_name: 'name', location_street: 'street', location_city: 'city', location_state: 'state', location_zip: 'zip', location_country: 'country', location_phone: 'phone', location_website: 'website', location_type: 'type', location_zone: 'zone', location_operator: 'operator', location_comments: 'comments', location_machines_ids: [ 20 ], place_id: 'tgtgtgtgtgtgtg', submitter_name: 'subname', submitter_email: 'subemail' }

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
        expect(sl.machines).to eq('Jolene (Pro) (Burrito, 1995),')
        expect(sl.place_id).to eq('tgtgtgtgtgtgtg')
        expect(sl.user_inputted_address).to eq('street, city, state, zip')
      end

      it 'should blank state for countries in COUNTRIES_WITHOUT_STATE' do
        FactoryBot.create(:machine, name: 'Jolene (Pro)', manufacturer: 'Burrito', year: '1995', id: 20)
        login(FactoryBot.create(:user, username: 'ssw', email: 'yeah@ok.com'))

        ApplicationController::COUNTRIES_WITHOUT_STATE.each do |country_code|
          post 'submitted_new_location', params: { region: region, location_name: 'name', location_street: 'street', location_city: 'city', location_state: 'some-state', location_zip: 'zip', location_country: country_code, location_machines_ids: [ 20 ], place_id: 'tgtgtgtgtgtgtg' }

          sl = SuggestedLocation.last
          expect(sl.state).to be_blank, "expected state to be blank for country #{country_code}, got '#{sl.state}'"
        end
      end
    end
  end
end
