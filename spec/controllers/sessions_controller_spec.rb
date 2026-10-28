require 'spec_helper'

describe SessionsController, type: :controller do
  before(:each) do
    @request.env['devise.mapping'] = Devise.mappings[:user]
  end

  describe '#new' do
    it 'stores a same-host referer, including its query string, as the return location' do
      request.env['HTTP_REFERER'] = 'http://test.host/map?by_location_id=16910&address=Revenge%20Of'

      get :new

      expect(session[:previous_url]).to eq('/map?by_location_id=16910&address=Revenge%20Of')
    end

    it 'ignores referers from other hosts' do
      request.env['HTTP_REFERER'] = 'https://evil.example.com/map?by_location_id=1'

      get :new

      expect(session[:previous_url]).to be_nil
    end

    it 'ignores referers that are auth pages' do
      request.env['HTTP_REFERER'] = 'http://test.host/users/join'

      get :new

      expect(session[:previous_url]).to be_nil
    end
  end
end
