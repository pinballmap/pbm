require 'spec_helper'

describe LocationsController do
  describe ':region/iphone.html' do
    it 'should route legacy mobile requests' do
      {:get => '/portland/iphone.html'}.should route_to(:controller => 'locations', :action => 'unknown_route', :page => 'iphone.html', :region => 'portland')
    end
  end
end
