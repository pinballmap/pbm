require 'spec_helper'

describe Api::V1::LocationsController, :type => :request do
  before(:each) do
    @region = FactoryGirl.create(:region, :name => 'portland')
    @location = FactoryGirl.create(:location, :region => @region, :state => 'OR', :zip => '97203')
    FactoryGirl.create(:user, :email => 'foo@bar.com', :region => @region)
    FactoryGirl.create(:user, :email => 'super_admin@bar.com', :region => nil, :is_super_admin => 1)
  end

  describe '#suggest' do
    it 'errors when region is not available' do
      post '/api/v1/locations/suggest.json?region_id=-1'
      expect(response).to be_success

      JSON.parse(response.body)['errors']['Failed to find region']
    end

    it 'emails admins on new location submission' do
      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          :to => ["foo@bar.com"],
          :bcc => ["super_admin@bar.com"],
          :from =>"admin@pinballmap.com",
          :subject => "PBM - New location suggested for the portland pinball map",
          :body => <<HERE
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
HERE
        )
      end

      post '/api/v1/locations/suggest.json', :region_id => @region.id.to_s, :location_name => 'name', :location_street => 'street', :location_city => 'city', :location_state => 'state', :location_zip => 'zip', :location_phone => 'phone', :location_website => 'website', :location_operator => 'operator', :location_machines => 'machines', :submitter_name => 'subname', :submitter_email => 'subemail'
      expect(response).to be_success

      JSON.parse(response.body)['msg']["Thanks for entering that location. We'll get it in the system as soon as possible."]
    end
  end

  describe '#update' do
    it 'only allows you to update description, website, and phone' do
      put '/api/v1/locations/' + @location.id.to_s + '.json?description=foo;website=http://bar;phone=baz;zip=97777'
      expect(response).to be_success

      updated_location = Location.find(@location.id)

      expect(updated_location.description).to eq('foo')
      expect(updated_location.website).to eq('http://bar')
      expect(updated_location.phone).to eq('baz')
      expect(updated_location.zip).to eq('97203')

      parsed_body = JSON.parse(response.body)
      expect(parsed_body.size).to eq(1)

      location = parsed_body['location']

      expect(location['description']).to eq('foo')
      expect(location['website']).to eq('http://bar')
      expect(location['phone']).to eq('baz')
      expect(location['zip']).to eq('97203')
    end
  end
end
