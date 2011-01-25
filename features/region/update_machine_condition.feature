Feature: update condition for location's machine
  In order to update a location's machine's condition
  As a guest
  I want to be able to update a condition on a machine

  @javascript
  Scenario: Add a new condition to a machine
    Given there is a location machine xref
    And I am on "Portland"'s home page
    And I press "Search"
    And I click to see the detail for "Test Location Name"
    And I click on the show machines link for "Test Location Name"
    Then the "machine_condition" field should contain "No Condition"
    When I fill in "machine_condition" with "This is a new condition"
    And I press "Update Condition"
    Then "Test Location Name"'s "Test Machine Name" should have the condition "This is a new condition"
