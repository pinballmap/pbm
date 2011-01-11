Feature: New Machine for Location
  In order to add machines to locations
  As a guest
  I want to be able to add machines to locations

  @javascript
  Scenario: Add machine by name
    Given there is a location machine xref
    And the following machines exist:
    |name|
    |Star Wars|
    |Medieval Madness|
    And I am on "Portland"'s home page
    And I select "Test Location Name" from "by_location_id"
    And I press "Search"
    And I follow "Test Location Name | 123 Pine | Portland"
    And I fill in "Add By Machine Name" with "Star Wars"
    And I press "Add"
    Then "Test Location Name" should have "Star Wars"

  @javascript
  Scenario: Add machine by id
    Given there is a location
    And the following machines exist:
    |name|
    |Star Wars|
    |Medieval Madness|
    And I am on "Portland"'s home page
    And I select "Test Location Name" from "by_location_id"
    And I press "Search"
    And I follow "Test Location Name | 123 Pine | Portland"
    And I select "Medieval Madness" from "add_machine_by_id"
    And I press "Add"
    Then "Test Location Name" should have "Medieval Madness"
