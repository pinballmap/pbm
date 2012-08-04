module GoogleAnalyticsHelper
  def analytics_js
    return nil unless Rails.env.production?

    return <<HERE
      var ga = document.createElement('script');
      ga.type = 'text/javascript'; ga.async = true;
      ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
      var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
HERE
  end
end
