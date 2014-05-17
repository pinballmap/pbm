require 'spec_helper'

describe Api::V1::LocationsController do

  describe '#update' do
    before(:each) do
      @region = FactoryGirl.create(:region, :name => 'portland')
      @location = FactoryGirl.create(:location, :region => @region, :state => 'OR', :zip => '97203')
    end

    it 'only allows you to update description, website, and phone' do
      put '/api/v1/locations/' + @location.id.to_s + '.json?description=foo;website=http://bar;phone=baz;zip=97777'
      expect(response).to be_success

      updated_location = Location.find(@location.id)

      updated_location.description.should == 'foo'
      updated_location.website.should == 'http://bar'
      updated_location.phone.should == 'baz'
      updated_location.zip.should == '97203'

      parsed_body = JSON.parse(response.body)
      parsed_body.size.should == 1

      location = parsed_body['location']

      expect(location['description']).to eq('foo')
      expect(location['website']).to eq('http://bar')
      expect(location['phone']).to eq('baz')
      expect(location['zip']).to eq('97203')
    end
  end
end
