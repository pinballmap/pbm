Feature: update condition for location's machine
  In order to update a location's machine's condition
  As a guest
  I want to be able to update a condition on a machine

  @javascript
  Scenario: Add a new condition to a machine
    Given there is a location machine xref
    And I am on "Portland"'s home page
    And I press the "location" search button
    And I update the machine condition for "Test Location Name"'s "Test Machine Name" to be "New Condition"
    Then "Test Location Name"'s "Test Machine Name" should have the condition "New Condition"
