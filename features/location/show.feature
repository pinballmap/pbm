Feature: Show Locations
  In order to scope out a location
  As a guest
  I want to look at a location

  Scenario: Show location
    Given a location exists with name: "Bar Cleo"
    And I am on the location detail page for "Bar Cleo"
    Then I should see "Name: Bar Cleo"

  Scenario: Back button
    Given a location exists with name: "Bar Cleo"
    And I am on the location detail page for "Bar Cleo"
    And I follow "Back"
    Then I should be on the locations page
