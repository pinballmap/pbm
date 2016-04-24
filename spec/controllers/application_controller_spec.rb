require 'spec_helper'

describe ApplicationController, type: :controller do
  controller do
    def index
      return '' if mobile_device?

      fail CanCan::AccessDenied
    end

    def after_sign_in_path_for(resource)
      super resource
    end
  end

  before(:each) do
    FactoryGirl.create(:region, name: 'portland', full_name: 'Portland')
  end

  describe 'CanCan AccessDenied' do
    it 'redirects to sign in page when you access a page that needs authorization' do
      expect_any_instance_of(ApplicationController).to receive(:set_current_user).and_return(nil)

      get :index

      expect(response).to redirect_to '/users/sign_in'
    end
  end

  describe '#mobile_device?' do
    it 'sets 1 to mobile param session when true' do
      expect_any_instance_of(ApplicationController).to receive(:set_current_user).and_return(nil)

      session[:mobile_param] = '1'

      get :index

      expect(response.body).to eq('')
    end
  end

  describe '#after_sign_in_path_for' do
    it 'redirects you to the main page' do
      user = FactoryGirl.create(:user)

      expect(controller.after_sign_in_path_for(user)).to eq('/')
    end
  end
end
