Feature: update condition for location's machine
  In order to update a location's machine's condition
  As a guest
  I want to be able to update a condition on a machine

  @javascript
  Scenario: Add a new condition to a machine
    Given "Cleo" is a location with the name "Bar Cleo" and the lat "12.12" and the lon "44.44" and the id "1"
    And "SW" is a machine with the name "Star Wars"
    And "XREF" is a location machine xref with the location "Cleo" and the machine "SW"
    When I am on the home page
    And I press "Search"
    And I follow "Bar Cleo | 123 Pine | Portland"
    Then the "machine_condition" field should contain "No Condition"
    When I fill in "machine_condition" with "This is a new condition"
    And I press "Update Condition"
    Then "Bar Cleo"'s "Star Wars" should have the condition "This is a new condition"
