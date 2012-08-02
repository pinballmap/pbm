Feature: Region main page
  In order to do pretty much everything on this website
  As a guest
  I want to do basic site navigation

  @javascript
  Scenario: Change navigation type
    Given there is a location machine xref
    And I am on "Portland"'s home page
    Then I should see "To search locations by location, please select a location from the drop down or use the text box"
    And I should not see "To search locations by machine, please select a machine from the drop down or use the text box" within "span.info"
    And my other search options should be "city location machine type operator zone"
    Given I switch to "machine" lookup
    Then I should see "To search locations by machine, please select a machine from the drop down or use the text box"
    And I should not see "To search locations by location, please select a location from the drop down or use text box" within "span.info"

  @javascript
  Scenario: Searching is automatically limited by region
    Given "Chicago" is a region with the name "chicago" and the id "2"
    And there is a location machine xref
    And I am on "Chicago"'s home page
    And I press the "location" search button
    Then I should not see the listing for "Test Location Name"

  @javascript
  Scenario: Search by location name from select
    Given there is a location machine xref
    And I am on "Portland"'s home page
    And I select "Test Location Name" from "by_location_id"
    And I press the "location" search button
    Then I should see the listing for "Test Location Name"

  @javascript
  Scenario: Search by machine name from select
    Given there is a location machine xref
    And I am on "Portland"'s home page
    And I switch to "machine" lookup
    And I select "Test Machine Name" from "by_machine_id"
    And I press the "machine" search button
    Then I should see the listing for "Test Location Name"

  @javascript
  Scenario: Search by machine name from select, limits to machines in region
    Given there is a location machine xref
    And there is a machine with the name "This is not in the region"
    And I am on "Portland"'s home page
    And I switch to "machine" lookup
    Then I should not see "This is not in the region"

  @javascript
  Scenario: Single location search automatically loads with machine detail visible
    Given there is a location machine xref
    And I am on "Portland"'s home page
    And I press the "location" search button
    Then I should see "Test Location Name"
    And I should see "303 Southeast 3rd Avenue | Portland"
    And I should see "ADD A PICTURE"
    And I should see "ADD NEW MACHINE TO THIS LOCATION"
    And I should see "SHOW MACHINES AT THIS LOCATION"
    And I should see "No Description"

  @javascript
  Scenario: Search by city
    Given there is a region with the name "portland" and the id "1"
    And the following locations exist:
      |name|city|region_id|
      |Cleo|Portland|1|
      |Sassy|Beaverton|1|
      |Zelda|Hillsboro|1|
      |Bawb|Hillsboro|1|
    And I am on "Portland"'s home page
    And I switch to "city" lookup
    And I select "Beaverton" from "by_city_id"
    And I press the "city" search button
    Then I should see the listing for "Sassy"

  @javascript
  Scenario: Search by zone
    Given there is a region with the name "portland" and the id "1"
    And there is a zone with the name "Alberta" and the id "2" and the region_id "1"
    And the following locations exist:
      |name|zone_id|region_id|
      |Cleo|1|1|
      |Sassy|2|1|
    And I am on "Portland"'s home page
    And I switch to "zone" lookup
    And I select "Alberta" from "by_zone_id"
    And I press the "zone" search button
    Then I should see the listing for "Sassy"
    And I should not see the listing for "Cleo"

  @javascript
  Scenario: Search by location type
    Given there is a region with the name "portland" and the id "1"
    And the following location types exist:
      |id|name|
      |1|bar|
      |2|playground|
      |3|bowling alley|
    And the following locations exist:
      |name|location_type_id|region_id|
      |Cleo|1|1|
      |Zelda|2|1|
      |Bawb|1|2|
    And I am on "Portland"'s home page
    And I switch to "type" lookup
    And I select "bar" from "by_type_id"
    And I press the "type" search button
    Then I should see the listing for "Cleo"
    And I should not see the listing for "Zelda"
    And I should not see the listing for "Bawb"
    And I should not see "bowling alley" within "select#by_type_id"

  @javascript
  Scenario: Search by operator
    Given there is a region with the name "portland" and the id "1"
    And the following operators exist:
      |id|name|region_id|
      |1|Sassco|1|
      |2|Quarter Bean|1|
      |3|Bawbco|2|
    And the following locations exist:
      |name|operator_id|region_id|
      |Cleo|1|1|
      |Zelda|2|1|
      |Bawb|1|2|
    And I am on "Portland"'s home page
    And I switch to "operator" lookup
    And I select "Sassco" from "by_operator_id"
    And I press the "operator" search button
    Then I should see the listing for "Cleo"
    And I should not see the listing for "Zelda"
    And I should not see the listing for "Bawb"

  @javascript
  Scenario: Displays location type if available
    Given there is a region with the name "portland" and the id "1"
    And there is a location type with the name "bar" and the id "1"
    And the following locations exist:
      |name|location_type_id|region_id|
      |Cleo|1|1|
      |Sass||1|
    And I am on "Portland"'s home page
    And I press the "location" search button
    Then I should see "Cleo (bar)"
    And I should see "Sass"

  @javascript
  Scenario: Location description displays appropriate values
    Given there is a location machine xref
    And I am on "Portland"'s home page
    And I press the "location" search button
    Then I should see "Click to enter location description/hours/etc"
    Given I update the location condition for "Test Location Name" to be "New Condition"
    And I press "Save"
    Then I should see "New Condition"

  @javascript
  Scenario: Default search type for region
    Given there is a region with the name "portland" and the default_search_type "city"
    And I am on "Portland"'s home page
    Then I should see "To search locations by city, please select a city from the drop down"
    And my other search options should be "location machine type operator zone"

  @javascript
  Scenario: Searches are displayed in alphabetical order
  Given there is a region with the name "portland" and the id "1"
  And the following locations exist:
    |name|region_id|
    |Cleo|1|
    |Sassy|1|
    |Zelda|1|
    |Bawb|1|
  And I am on "Portland"'s home page
  And I press the "location" search button
  And I wait for 1 seconds
  Then the order of the listings should be "Bawb, Cleo, Sassy, Zelda"

  @javascript
  Scenario: N or more machines
    Given there is a region with the name "portland" and the id "1"
    And the following zones exist:
      |id|name|region_id|
      |1|Baz|1|
    And the following locations exist:
      |id|name|region_id|zone_id|
      |1|Foo|1|1|
      |2|Bar|1|1|
    And the following machines exist:
      |id|
      |1|
      |2|
    And the following location machine xrefs exist:
      |location_id|machine_id|
      |1|1|
      |2|1|
      |2|2|
    And I am on "Portland"'s home page
    And I switch to "zone" lookup
    And I select "2" from "by_at_least_n_machines"
    And I press the "zone" search button
    Then I should see the listing for "Bar"
    And I should not see the listing for "Foo"

  @javascript
  Scenario: Direct link for location
  Given there is a region with the name "portland" and the id "1"
  And the following locations exist:
    |id|name|region_id|
    |1|Cleo|1|
  And I navigate to the direct link for region "portland" location "1"
  And I wait for 1 seconds
  Then I should see the listing for "Cleo"

  @javascript
  Scenario: Direct link for city
  Given there is a region with the name "portland" and the id "1"
  And the following locations exist:
    |id|name|city|region_id|
    |1|Cleo|portland|1|
    |2|Bawb|beaverton|1|
  And I navigate to the direct link for region "portland" city "portland"
  And I wait for 1 seconds
  Then I should see the listing for "Cleo"
