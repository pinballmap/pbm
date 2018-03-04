require 'spec_helper'

describe LocationMachineXrefsController, type: :controller do
  before(:each) do
    @region = FactoryBot.create(:region, name: 'portland')
    @location = FactoryBot.create(:location, id: 1)
    @user = FactoryBot.create(:user, username: 'ssw', email: 'ssw@yeah.com')
    FactoryBot.create(:user, email: 'foo@bar.com', region: @region)
  end

  describe 'create' do
    it 'should send email on new machine creation' do
      login(@user)

      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          to: ['foo@bar.com'],
          from: 'admin@pinballmap.com',
          subject: 'PBM - New machine name',
          body: "foo\nTest Location Name\nportland\n(entered from 0.0.0.0 via #{request.user_agent} by ssw (ssw@yeah.com))"
        )
      end

      post 'create', params: { region: 'portland', add_machine_by_name_1: 'foo', add_machine_by_id_1: '', location_id: @location.id }
    end

    it 'should send email on new machine creation - notifies if staging site origin' do
      login(@user)

      @request.host = 'pinballmapstaging.herokuapp.com'

      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          subject: '(STAGING) PBM - New machine name'
        )
      end

      post 'create', params: { region: 'portland', add_machine_by_name_1: 'foo', add_machine_by_id_1: '', location_id: @location.id }
    end

    it "should return undef if you don't supply a machine name or id" do
      login(@user)

      expect(Pony).to_not receive(:mail)

      post 'create', params: { region: 'portland', add_machine_by_id_1: '', add_machine_by_name_1: '', location_id: @location.id }

      expect(LocationMachineXref.all.size).to eq(0)
    end
  end
end
