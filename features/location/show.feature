Feature: Show Locations
  In order to scope out a location
  As a guest
  I want to look at a location

  Scenario: Show location
    Given a location exists with name: "Bar Cleo"
    And I am on "Bar Cleo"'s detail page
    Then I should see "Name: Bar Cleo"
  
  Scenario: Back button
    Given a location exists with name: "Bar Cleo"
    And I am on "Bar Cleo"'s detail page
    And I follow "Back"
    Then I should be on the locations page
