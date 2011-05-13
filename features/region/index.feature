Feature: Region main page
  In order to do pretty much everything on this website
  As a guest
  I want to do basic site navigation

  @javascript
  Scenario: Change navigation type
    Given there is a location machine xref
    And I am on "Portland"'s home page
    Then I should see "To search locations please select a place from the drop down or begin typing in the text box."
    And I should not see "To find a machine please select one from the drop down or use the text box." within "span.info"
    And my other search options should be "city machine type zone"
    Given I switch to "machine" lookup
    Then I should see "To find a machine please select one from the drop down or use the text box."
    And I should not see "To search locations please select a place or region from the drop down or begin typing in the text box." within "span.info"

  @javascript
  Scenario: Searching is automatically limited by region
    Given "Chicago" is a region with the name "chicago" and the id "1"
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
    And I should see "123 Pine | Portland"
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
    And I select "Beaverton" from "by_city"
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
    And the following locations exist:
      |name|location_type_id|region_id|
      |Cleo|1|1|
      |Zelda|2|1|
      |Bawb|1|2|
    And I am on "Portland"'s home page
    And I switch to "type" lookup
    And I select "bar" from "by_type"
    And I press the "type" search button
    Then I should see the listing for "Cleo"
    And I should not see the listing for "Zelda"
    And I should not see the listing for "Bawb"

  @javascript
  Scenario: Displays location type if available
    Given there is a region with the name "Portland" and the id "1"
    And there is a location type with the name "bar"
    And the following locations exist:
      |name|location_type|region_id|
      |Cleo|name: bar|1|
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
    Then I should see "Click to enter description"
    Given I update the location condition for "Test Location Name" to be "New Condition"
    And I press "Save"
    Then I should see "New Condition"
