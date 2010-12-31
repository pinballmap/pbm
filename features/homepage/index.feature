Feature: Main page
  In order to do pretty much everything on this website
  As a guest
  I want to do basic site navigation

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

  @javascript
  Scenario: Search by location name from select
    Given "Cleo" is a location with the name "Bar Cleo" and the street "123 pine" and the city "Portland"
    And "SW" is a machine with the name "Star Wars"
    And there is a location machine xref with the location "Cleo" and the machine "SW"
    And I am on the home page
    And I select "Bar Cleo" from "by_location_id"
    And I press "Search"
    Then I should see "Bar Cleo | 123 pine | Portland # Star Wars"

  @javascript
  Scenario: Search by machine name from select
    Given "Cleo" is a location with the name "Bar Cleo" and the street "123 pine" and the city "Portland"
    And "SW" is a machine with the name "Star Wars"
    And there is a location machine xref with the location "Cleo" and the machine "SW"
    And I am on the home page
    And I select "Star Wars" from "by_machine_id"
    And I press "Search"
    Then I should see "Bar Cleo | 123 pine | Portland # Star Wars"

  @javascript
  Scenario: Location detail shows the stuff that I want it to show
    Given "Cleo" is a location with the name "Bar Cleo" and the street "123 pine" and the city "Portland" and the lat "12.12" and the lon "44.44" and the id "1"
    And "SW" is a machine with the name "Star Wars"
    And there is a location machine xref with the location "Cleo" and the machine "SW"
    And I am on the home page
    And I select "Bar Cleo" from "by_location_id"
    And I press "Search"
    Then I should see "Bar Cleo | 123 pine | Portland # Star Wars"
    And I follow "show_location_detail_1"
    Then I should see "Bar Cleo | 123 pine | Portland"
    And I should see "Add Machine"
    And I should see the "add_machine_by_id_1" input
    And I should see the "add_machine_by_name_1" input
    And I should see "Star Wars"
