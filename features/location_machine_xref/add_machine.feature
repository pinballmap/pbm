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
    And I press the "location" search button
    And I click on the add machine link for "Test Location Name"
    And I fill in "add_machine_by_name" with "Star Wars"
    And I wait for 1 seconds
    And I press "add"
    And I wait for 1 seconds
    Then "Test Location Name" should have "Star Wars"

  @javascript
  Scenario: Add machine by id
    Given there is a location
    And the following machines exist:
    |name|
    |Star Wars|
    |Medieval Madness|
    And I am on "Portland"'s home page
    And I press the "location" search button
    And I click on the add machine link for "Test Location Name"
    And I select "Medieval Madness" from "add_machine_by_id"
    And I wait for 1 seconds
    And I press "add"
    And I wait for 1 seconds
    Then "Test Location Name" should have "Medieval Madness"

  @javascript
  Scenario: Add machine by id
    Given there is a location machine_xref
    And I am on "Portland"'s home page
    And I press the "location" search button
    And I click on the add machine link for "Test Location Name"
    And I fill in "add_machine_by_name" with "Test Machine Name"
    And I wait for 1 seconds
    And I press "add"
    And I wait for 1 seconds
    Then "Test Location Name" should only have "Test Machine Name"
