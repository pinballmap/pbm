require "spec_helper"

describe IfpaLocationMatcher do
  def tournament(attrs = {})
    {
      "location_name" => "",
      "address1" => "5901 Chandler Court",
      "city" => "Westerville",
      "postal_code" => "43082",
      "country_code" => "US",
      "latitude" => "40.1544",
      "longitude" => "-82.9233"
    }.merge(attrs)
  end

  def location(attrs = {})
    FactoryBot.create(:location, { name: "Grizzlybird Brewing", street: "5901 Chandler Ct", city: "Westerville", state: "OH", zip: "43082", lat: 40.1544, lon: -82.9233 }.merge(attrs))
  end

  it "matches on zip and close coordinates, like the old import" do
    l = location(street: "Somewhere Else")
    result = IfpaLocationMatcher.match(tournament("latitude" => "40.1546"))

    expect(result.location).to eq(l)
    expect(result.methods).to eq([ :zip_proximity ])
  end

  it "doesn't match on zip when the coordinates are too far apart" do
    location(street: "Somewhere Else", lat: 40.1564)

    expect(IfpaLocationMatcher.match(tournament).location).to be_nil
  end

  it "matches an address despite suffix differences, a typo, a suite, and a wrong zip" do
    l = location(lat: 40.1580)
    result = IfpaLocationMatcher.match(tournament("address1" => "5901 Chandlr Court Suite 3", "postal_code" => "43068"))

    expect(result.location).to eq(l)
    expect(result.methods).to eq([ :address ])
  end

  it "doesn't match an address with a different house number" do
    location(lat: 40.1580)

    expect(IfpaLocationMatcher.match(tournament("address1" => "5907 Chandler Court")).location).to be_nil
  end

  it "takes the house number from raw_address when address1 leaves it out" do
    l = location(lat: 40.1580)
    result = IfpaLocationMatcher.match(tournament("address1" => "Chandler Court", "raw_address" => "Grizzlybird Brewing\r\n5901 Chandler Ct, Westerville, OH 43082, US"))

    expect(result.location).to eq(l)
    expect(result.methods).to eq([ :address ])
  end

  it "takes the house number from raw_address when search results join its lines with two spaces" do
    l = location(lat: 40.1580)
    result = IfpaLocationMatcher.match(tournament("address1" => "Chandler Court", "raw_address" => "Grizzlybird Brewing  5901 Chandler Ct, Westerville, OH 43082, US"))

    expect(result.location).to eq(l)
    expect(result.methods).to eq([ :address ])
  end

  it "ignores raw_address house numbers on a different street" do
    location(lat: 40.1580)

    expect(IfpaLocationMatcher.match(tournament("address1" => "Chandler Court", "raw_address" => "5901 Main St, Westerville, OH 43082")).location).to be_nil
  end

  it "doesn't match an address when neither city nor zip agree" do
    location(lat: 40.1580, city: "Columbus", zip: "43229")

    expect(IfpaLocationMatcher.match(tournament).location).to be_nil
  end

  it "doesn't match an address beyond the search radius" do
    location(lat: 40.17)

    expect(IfpaLocationMatcher.match(tournament).location).to be_nil
  end

  it "matches on location_name when it's present and the coordinates are close" do
    l = location(street: "Somewhere Else", zip: "99999", lat: 40.1550)
    result = IfpaLocationMatcher.match(tournament("location_name" => "Grizzlybird Brewing Company"))

    expect(result.location).to eq(l)
    expect(result.methods).to eq([ :name ])
  end

  it "prefers the candidate passing the most checks" do
    location(name: "Next Door Bar", street: "5903 Chandler Ct")
    l = location

    expect(IfpaLocationMatcher.match(tournament).location).to eq(l)
  end

  it "returns no match when candidates tie" do
    a = location(name: "Bar One", street: "Somewhere Else")
    b = location(name: "Bar Two", street: "Another Place")
    result = IfpaLocationMatcher.match(tournament)

    expect(result.location).to be_nil
    expect(result.ambiguous_location_ids).to contain_exactly(a.id, b.id)
  end

  it "skips locations in a different country" do
    location(country: "CA")

    expect(IfpaLocationMatcher.match(tournament).location).to be_nil
  end

  it "returns no match without coordinates" do
    location

    expect(IfpaLocationMatcher.match(tournament("latitude" => "", "longitude" => "0")).location).to be_nil
  end

  describe ".split_street" do
    it "only reads trailing house numbers when asked" do
      expect(IfpaLocationMatcher.split_street("Highway 99")).to eq([ nil, "hwy 99" ])
      expect(IfpaLocationMatcher.split_street("Hauptstraße 12", trailing_numbers: true)).to eq([ "12", "hauptstrasse" ])
      expect(IfpaLocationMatcher.split_street("303 Southeast 3rd Avenue #200")).to eq([ "303", "se 3rd ave" ])
      expect(IfpaLocationMatcher.split_street("2020 32 AVE N.E.")).to eq([ "2020", "32 ave ne" ])
      expect(IfpaLocationMatcher.split_street("100 S. W. Main St.")).to eq([ "100", "sw main st" ])
    end
  end
end
