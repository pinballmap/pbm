require 'spec_helper'

describe Api::V1::LocationsController do

  describe '#index' do
    before(:each) do
      @portland = FactoryGirl.create(:region, :name => 'portland')
      @la = FactoryGirl.create(:region, :name => 'la')
    end

    it 'sends back additional, non-db fields' do
      FactoryGirl.create(:user, :region => @portland, :email => 'not@primary.com')
      FactoryGirl.create(:user, :region => @portland, :email => 'is@primary.com', :is_primary_email_contact => 1)

      get '/api/v1/regions.json'
      expect(response).to be_success

      parsed_body = JSON.parse(response.body)
      parsed_body.size.should == 1

      regions = parsed_body['regions']
      regions.size.should == 2

      expect(regions[0]['name']).to eq('portland')
      expect(regions[0]['primary_email_contact']).to eq('is@primary.com')
      expect(regions[0]['all_admin_email_addresses']).to eq(["not@primary.com", "is@primary.com"])

      expect(regions[1]['name']).to eq('la')
      expect(regions[1]['primary_email_contact']).to eq('email_not_found@noemailfound.noemail')
      expect(regions[1]['all_admin_email_addresses']).to eq(["email_not_found@noemailfound.noemail"])
    end
  end
end
