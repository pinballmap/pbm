require 'spec_helper'

describe GoogleAnalyticsHelper do
  describe '#analytics_js' do
    it 'should output js for google analytics' do
      helper.analytics_js.should == nil

      Rails.env = 'production'
      helper.analytics_js.should == <<HERE
      var ga = document.createElement('script');
      ga.type = 'text/javascript'; ga.async = true;
      ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
      var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
HERE
      Rails.env = 'development'
    end
  end
end
