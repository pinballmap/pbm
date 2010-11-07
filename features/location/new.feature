Feature: New Locations
  In order to create a new location
  As a guest
  I want to create locations

  Scenario: Locations List
    Given I am on the new_location page
    And I fill in "Name" with "Cleo"
    And I fill in "Street" with "123 Pine"
    And I fill in "City" with "Portland"
    And I fill in "State" with "OR"
    And I fill in "Zip" with "97211"
    And I press "Create Location"
    Then I should be on "Cleo"'s detail page
    And a location should exist with name: "Cleo"

  Scenario: Required fields not filled in
    Given I am on the new_location page
    And I press "Create Location"
    Then I should be on the locations page
    And I should see "can't be blank"
