require 'spec_helper'

describe LocationMachineXrefsController, type: :controller do
  before(:each) do
    @region = FactoryBot.create(:region, name: 'portland')
    @location = FactoryBot.create(:location, id: 1)
    @user = FactoryBot.create(:user, username: 'ssw', email: 'ssw@yeah.com')
    FactoryBot.create(:user, email: 'foo@bar.com', region: @region)
  end

  describe 'create' do
    it 'should enqueue an email on new machine creation' do
      login(@user)

      expect { post 'create', params: { add_machine_by_name_1: 'foo', add_machine_by_id_1: '', location_id: @location.id } }.to have_enqueued_job(ActionMailer::MailDeliveryJob).with('AdminMailer', 'new_machine_name', 'deliver_now', { params: { to_users: ['foo@bar.com'], subject: 'Pinball Map - New machine name', machine_name: 'foo', location_name: 'Test Location Name', remote_ip: '0.0.0.0', user_agent: 'Rails Testing', user_info: ' by ssw (ssw@yeah.com)' }, args: [] })
    end

    it 'should send email on new machine creation - notifies if staging site origin' do
      login(@user)

      @request.host = 'pbmstaging.com'

      expect { post 'create', params: { add_machine_by_name_1: 'foo', add_machine_by_id_1: '', location_id: @location.id } }.to have_enqueued_job(ActionMailer::MailDeliveryJob).with('AdminMailer', 'new_machine_name', 'deliver_now', { params: { to_users: ['foo@bar.com'], subject: '(STAGING) Pinball Map - New machine name', machine_name: 'foo', location_name: 'Test Location Name', remote_ip: '0.0.0.0', user_agent: 'Rails Testing', user_info: ' by ssw (ssw@yeah.com)' }, args: [] })
    end

    it "should return undef if you don't supply a machine name or id" do
      login(@user)

      post 'create', params: { region: 'portland', add_machine_by_id_1: '', add_machine_by_name_1: '', location_id: @location.id }
      expect(LocationMachineXref.all.size).to eq(0)
    end
  end
end
