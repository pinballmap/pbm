require 'spec_helper'

describe RegionsController, :type => :controller do
  before(:each) do
    @portland = FactoryGirl.create(:region, :name => 'portland')
  end

  describe '#show' do
    it 'finds region by id' do
      expect_any_instance_of(ApplicationController).to receive(:set_current_user).and_return(nil)

      get :show, :format => :json, :region => @portland.name, :id => @portland.id

      expect(response.body).to include('portland')
    end
  end
end
