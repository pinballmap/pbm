require 'spec_helper'

describe GoogleAnalyticsHelper do
  describe '#analytics_js' do
    it 'should output js for google analytics' do
      expect(helper.analytics_js).to eq(nil)

      Rails.env = 'production'
      expect(helper.analytics_js).to eq(<<HERE)
      var ga = document.createElement('script');
      ga.type = 'text/javascript'; ga.async = true;
      ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
      var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
HERE
      Rails.env = 'development'
    end
  end
end
