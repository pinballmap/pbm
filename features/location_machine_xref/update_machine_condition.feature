Feature: update condition for location's machine
  In order to update a location's machine's condition
  As a guest
  I want to be able to update a condition on a machine
  
  @javascript
  Scenario: Machines with no condition have default text
    Given there is a location machine xref
    And I am on "Portland"'s home page
    And I press the "location" search button
    Then I should see "Click to enter machine description"

  @javascript
  Scenario: Add a new condition to a machine
    Given there is a location machine xref
    And I am on "Portland"'s home page
    And I press the "location" search button
    And I update the machine condition for "Test Location Name"'s "Test Machine Name" to be "New Condition"
    And I press "Save"
    Then "Test Location Name"'s "Test Machine Name" should have the condition "New Condition"

  @javascript
  Scenario: Cancel condition editing
    Given there is a location machine xref
    And I am on "Portland"'s home page
    And I press the "location" search button
    And I update the machine condition for "Test Location Name"'s "Test Machine Name" to be "New Condition"
    And I press "Save"
    And I update the machine condition for "Test Location Name"'s "Test Machine Name" to be "Condition That I Hope Will Be Rejected"
    And I press "Cancel"
    Then "Test Location Name"'s "Test Machine Name" should have the condition "New Condition"
