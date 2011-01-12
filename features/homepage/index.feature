Feature: Main page
  In order to do pretty much everything on this website
  As a guest
  I want to do basic site navigation

  Scenario: Searching is automatically limited by region
    Given "Chicago" is a region with the name "chicago" and the id "1"
    And there is a location machine xref
    And I am on "Chicago"'s home page
    And I press "Search"
    Then I should not see "Test Location Name"

  @javascript
  Scenario: Search by location name from select
    Given there is a location machine xref
    And I am on "Portland"'s home page
    And I select "Test Location Name" from "by_location_id"
    And I press "Search"
    Then I should see "Test Location Name | 123 Pine | Portland # Test Machine Name"

  @javascript
  Scenario: Search by machine name from select
    Given there is a location machine xref
    And I am on "Portland"'s home page
    And I select "Test Machine Name" from "by_machine_id"
    And I press "Search"
    Then I should see "Test Location Name | 123 Pine | Portland # Test Machine Name"

  @javascript
  Scenario: Location detail shows the stuff that I want it to show
    Given there is a location machine xref
    And I am on "Portland"'s home page
    And I select "Test Location Name" from "by_location_id"
    And I press "Search"
    Then I should see "Test Location Name | 123 Pine | Portland # Test Machine Name"
    And I follow "Test Location Name | 123 Pine | Portland"
    Then I should see "Test Location Name | 123 Pine | Portland"
    And I should see "Add Machine"
    And I should see the "add_machine_by_id" input
    And I should see the "add_machine_by_name" input
    And I should see "Test Machine Name"

  @javascript
  Scenario: Search by city
    Given there is a region with the name "portland" and the id "1"
    Given the following locations exist:
      |name|city|region_id|
      |Cleo|Portland|1|
      |Sassy|Beaverton|1|
      |Zelda|Hillsboro|1|
      |Bawb|Hillsboro|1|
    And I am on "Portland"'s home page
    And I select "Beaverton" from "by_city"
    And I press "Search"
    Then I should see "Sassy"

  @javascript
  Scenario: Search by zone
    Given there is a region with the name "portland" and the id "1"
    And there is a zone with the name "Alberta" and the id "1" and the region_id "1"
    And the following locations exist:
      |name|zone_id|region_id|
      |Cleo|1|1|
      |Zelda|1|1|
      |Sassy|2|1|
    And I am on "Portland"'s home page
    And I select "Alberta" from "by_zone_id"
    And I press "Search"
    Then I should see "Cleo | 123 Pine"
    And I should see "Zelda | 123 Pine"
    And I should not see "Sassy | 123 Pine"
