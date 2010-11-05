Feature: Edit Locations
  In order to edit a location
  As a guest
  I want to edit the location

  Scenario: Edit name
    Given a location exists with name: "Bar Cleo"
    And I am on "Bar Cleo"'s edit page
    And I fill in "Name" with "Sass"
    And I press "Update Location"
    Then I should be on "Sass"'s detail page
    And I should see "Sass"
    And I should not see "Bar Cleo"

  Scenario: Back button
    Given a location exists with name: "Bar Cleo"
    And I am on "Bar Cleo"'s edit page
    And I follow "Back"
    Then I should be on the locations page
