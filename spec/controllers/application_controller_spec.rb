require 'spec_helper'

describe ApplicationController, type: :controller do
  controller do
    def index
      return '' if mobile_device?

      raise CanCan::AccessDenied
    end

    def after_sign_in_path_for(resource)
      super resource
    end

    def after_sign_out_path_for(resource)
      super resource
    end
  end

  before(:each) do
    FactoryBot.create(:region, name: 'portland', full_name: 'Portland')
  end

  describe 'CanCan AccessDenied' do
    it 'redirects to login page when you access a page that needs authorization' do
      get :index

      expect(response).to redirect_to '/users/login'
    end
  end

  describe '#mobile_device?' do
    it 'sets 1 to mobile param session when true' do
      session[:mobile_param] = '1'

      get :index, format: :json

      expect(response.body).to eq('')
    end
  end

  describe '#after_sign_in_path_for' do
    it 'redirects you to the main page' do
      user = FactoryBot.create(:user)

      expect(controller.after_sign_in_path_for(user)).to eq('/')
    end
  end

  describe '#after_sign_out_path_for' do
    it 'returns root path of you came from admin' do
      request.env['HTTP_REFERER'] = 'admin'

      user = FactoryBot.create(:user)

      expect(controller.after_sign_out_path_for(user)).to eq('/')
    end

    it 'returns you to referrer page if it was not admin' do
      request.env['HTTP_REFERER'] = 'portland'

      user = FactoryBot.create(:user)

      expect(controller.after_sign_out_path_for(user)).to eq('portland')
    end
  end
end
