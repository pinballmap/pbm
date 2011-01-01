Feature: Autocomplete
  In order to test autocomplete functionality
  As a guest
  I want to test autocomplete functionality

  @javascript
  Scenario: Add by machine name from input with autocomplete
    Given "Cleo" is a location with the name "Bar Cleo" and the lat "12.12" and the lon "44.44" and the id "1"
    And the following machines exist:
      |name|
      |Sassy Madness|
      |Sassy From The Black Lagoon|
      |Cleo Game|
    And I am on the home page
    And I select "Bar Cleo" from "by_location_id"
    And I press "Search"
    And I follow "show_location_detail_1"
    And I fill in "add_machine_by_name" with "Sassy"
    And I wait for 1 second
    Then I should see the following autocomplete options:
      |Sassy Madness|
      |Sassy From The Black Lagoon|

  @javascript
  Scenario: Search by machine name from input with autocomplete
    Given the following machines exist:
      |name|
      |Sassy Madness|
      |Sassy From The Black Lagoon|
      |Cleo Game|
    And I am on the home page
    When I fill in "Machine Name" with "Sassy"
    And I wait for 1 second
    Then I should see the following autocomplete options:
      |Sassy Madness|
      |Sassy From The Black Lagoon|

  @javascript
  Scenario: Search by location name from input with autocomplete
    Given the following locations exist:
      |name|
      |Cleo North|
      |Cleo South|
      |Sassy|
    And I am on the home page
    When I fill in "Location Name" with "Cleo"
    And I wait for 1 second
    Then I should see the following autocomplete options:
      |Cleo North|
      |Cleo South|
