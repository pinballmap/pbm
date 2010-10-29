require "spec_helper"

describe LocationsController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/locations" }.should route_to(:controller => "locations", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/locations/new" }.should route_to(:controller => "locations", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/locations/1" }.should route_to(:controller => "locations", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/locations/1/edit" }.should route_to(:controller => "locations", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/locations" }.should route_to(:controller => "locations", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/locations/1" }.should route_to(:controller => "locations", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/locations/1" }.should route_to(:controller => "locations", :action => "destroy", :id => "1")
    end

  end
end
