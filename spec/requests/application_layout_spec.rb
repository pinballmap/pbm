require 'spec_helper'

describe 'application layout', type: :request do
  def body_onload
    Nokogiri::HTML(response.body).at('body')['onload']
  end

  it 'keeps search params inside JS string literals in the body onload handler' do
    get '/map', params: { by_city_name: "x');alert(1);//", lat: '45.5' }

    expect(response).to be_successful
    expect(body_onload).to include(%q{"x');alert(1);//"})
    expect(body_onload).not_to include("'x')")
    expect(body_onload).to include('"45.5"')
  end

  it 'passes blank strings for missing search params' do
    get '/map'

    expect(body_onload).to include('"", "", ""')
    expect(body_onload).not_to include(", ''")
  end
end
