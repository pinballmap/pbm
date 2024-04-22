require 'spec_helper'

describe LocationMachineXrefsController, type: :controller do
  before(:each) do
    @region = FactoryBot.create(:region, name: 'portland')
    @location = FactoryBot.create(:location, id: 1)
    @user = FactoryBot.create(:user, username: 'ssw', email: 'ssw@yeah.com')
    FactoryBot.create(:user, email: 'foo@bar.com', region: @region)

    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
  end

  after(:each) do
    ActionMailer::Base.deliveries.clear
  end

  describe 'create' do
    it 'should send email on new machine creation' do
      login(@user)

      expect do
        post 'create', params: { add_machine_by_name_1: 'foo', add_machine_by_id_1: '', location_id: @location.id }
        email = ActionMailer::Base.deliveries.last
        expect(email.subject).to eq('Pinball Map - New machine name')
        expect(email.from).to eq(['admin@pinballmap.com'])
        expect(email.to).to eq(['foo@bar.com'])
        expect(email.body).to have_content('Machine name: foo')
        expect(email.body).to have_content('Location: Test Location Name')
        expect(email.body).to have_content('(entered from 0.0.0.0 Rails Testing by ssw (ssw@yeah.com))')
      end.to change { ActionMailer::Base.deliveries.size }.by(1)
    end

    it 'should send email on new machine creation - notifies if staging site origin' do
      login(@user)

      @request.host = 'pbmstaging.com'
      expect do
        post 'create', params: { region: 'portland', add_machine_by_name_1: 'foo', add_machine_by_id_1: '', location_id: @location.id }
        email = ActionMailer::Base.deliveries.last
        expect(email.subject).to eq('(STAGING) Pinball Map - New machine name')
      end.to change { ActionMailer::Base.deliveries.size }.by(1)
    end

    it "should return undef if you don't supply a machine name or id" do
      login(@user)
      expect(ActionMailer::Base.deliveries.count).to eq(0)

      post 'create', params: { region: 'portland', add_machine_by_id_1: '', add_machine_by_name_1: '', location_id: @location.id }
      expect(LocationMachineXref.all.size).to eq(0)
    end
  end
end
