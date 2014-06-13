require 'spec_helper'

describe Api::V1::LocationsController do
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
      Pony.should_receive(:mail) do |mail|
        mail.should == {
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
        }
      end

      post '/api/v1/locations/suggest.json', :region_id => @region.id.to_s, :location_name => 'name', :location_street => 'street', :location_city => 'city', :location_state => 'state', :location_zip => 'zip', :location_phone => 'phone', :location_website => 'website', :location_operator => 'operator', :location_machines => 'machines', :submitter_name => 'subname', :submitter_email => 'subemail'
      expect(response).to be_success

      JSON.parse(response.body)['msg']["Thanks for entering that location. We'll get it in the system as soon as possible."]
    end
  end

  describe '#update' do
    it 'only allows you to update description, website, and phone' do
      put '/api/v1/locations/' + @location.id.to_s + '.json?description=foo;website=http://bar;phone=5555555555;zip=97777'
      expect(response).to be_success

      updated_location = Location.find(@location.id)

      updated_location.description.should == 'foo'
      updated_location.website.should == 'http://bar'
      updated_location.phone.should == '555-555-5555'
      updated_location.zip.should == '97203'

      parsed_body = JSON.parse(response.body)
      parsed_body.size.should == 1

      location = parsed_body['location']

      expect(location['description']).to eq('foo')
      expect(location['website']).to eq('http://bar')
      expect(location['phone']).to eq('555-555-5555')
      expect(location['zip']).to eq('97203')
    end

    it 'responds with an error if an invalid phone number is sent' do
      put '/api/v1/locations/' + @location.id.to_s + '.json?phone=baz'

      expect(response).to be_success

      expect(JSON.parse(response.body)['errors']).to eq(['Phone format invalid, please use ###-###-####'])

      put '/api/v1/locations/' + @location.id.to_s + '.json?phone=444-4444'

      expect(response).to be_success

      expect(JSON.parse(response.body)['errors']).to eq(['Phone format invalid, please use ###-###-####'])

      put '/api/v1/locations/' + @location.id.to_s + '.json?phone=11-444-4444'

      expect(response).to be_success

      expect(JSON.parse(response.body)['errors']).to eq(['Phone format invalid, please use ###-###-####'])
    end
  end
end
