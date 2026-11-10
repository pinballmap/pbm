require 'spec_helper'

describe 'non-XHR rate limit', type: :request do
  before(:each) do
    @location = FactoryBot.create(:location)
    allow(Rails.cache).to receive(:increment).and_call_original
    allow(Rails.cache).to receive(:increment).with(/\Arate-limit:non_xhr:/, any_args).and_return(11)
  end

  let(:browser_ua) { { 'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36' } }

  it 'limits non-XHR requests to JS-only endpoints' do
    get "/locations/#{@location.id}/render_machines", headers: browser_ua
    expect(response).to have_http_status(:too_many_requests)

    post '/get_bounds', headers: browser_ua
    expect(response).to have_http_status(:too_many_requests)
  end

  it 'ignores XHR requests' do
    get "/locations/#{@location.id}/render_machines", headers: browser_ua, xhr: true
    expect(response).to be_successful
  end

  it 'ignores bots' do
    get "/locations/#{@location.id}/render_machines", headers: { 'User-Agent' => 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)' }
    expect(response).to be_successful
  end
end
