require 'spec_helper'

describe ApplicationController, :type => :controller do
  controller do
    def index
      if (mobile_device?)
        return ""
      end
      raise CanCan::AccessDenied
    end

    def after_sign_in_path_for(resource)
        super resource
    end
  end

  before(:each) do
    expect_any_instance_of(ApplicationController).to receive(:set_current_user).and_return(nil)

    region = FactoryGirl.create(:region, :name => 'portland', :full_name => 'Portland')
  end

  describe 'CanCan AccessDenied' do
    it 'redirects to sign in page when you access a page that needs authorization' do
      get :index

      expect(response).to redirect_to '/users/sign_in'
    end
  end

  describe '#mobile_device?' do
    it 'sets 1 to mobile param session when true' do
      session[:mobile_param] = "1"

      get :index

      expect(response.body).to eq('')
    end
  end
end
