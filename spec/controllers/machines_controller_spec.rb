require 'spec_helper'

describe MachinesController, :type => :controller do
  before(:each) do
    FactoryGirl.create(:region, :name => 'portland')
    FactoryGirl.create(:machine, :name => 'Cleo')
  end

  describe '#index' do
    it 'should honor the by_name scope' do
      expect_any_instance_of(ApplicationController).to receive(:set_current_user).and_return(nil)

      get :index, :format => :json, :region => 'portland'

      expect(response.body).to include('Cleo')
    end
  end
end
