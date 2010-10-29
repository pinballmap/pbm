require 'spec_helper'

describe "locations/edit.html.erb" do
  before(:each) do
    @location = assign(:location, stub_model(Location,
      :new_record? => false,
      :name => "MyString",
      :street => "MyString",
      :city => "MyString",
      :state => "MyString",
      :zip => "MyString",
      :phone => "MyString",
      :lat => 1.5,
      :lon => 1.5,
      :website => "MyString"
    ))
  end

  it "renders the edit location form" do
    render

    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    assert_select "form", :action => location_path(@location), :method => "post" do
      assert_select "input#location_name", :name => "location[name]"
      assert_select "input#location_street", :name => "location[street]"
      assert_select "input#location_city", :name => "location[city]"
      assert_select "input#location_state", :name => "location[state]"
      assert_select "input#location_zip", :name => "location[zip]"
      assert_select "input#location_phone", :name => "location[phone]"
      assert_select "input#location_lat", :name => "location[lat]"
      assert_select "input#location_lon", :name => "location[lon]"
      assert_select "input#location_website", :name => "location[website]"
    end
  end
end
