Feature: Lookup Locations
  In order to check out some locations
  As a guest
  I want to lookup locations

  Scenario: Locations List
    Given a location exists with name: "Bar Cleo"
    And I am on the index of locations
    Then I should see "Bar Cleo"

  Scenario: Pagination
    Given there are 51 locations
    And a location exists with name: "Bar Cleo"
    When I go to the index of locations
    Then I should not see "Bar Cleo"

  Scenario: New location
    Given I am on the index of locations
    When I follow "New Location"
    Then I should be on "new location"

  Scenario: Show location
    Given a location exists with name: "Bar Cleo"
    And I am on the index of locations
    When I follow "Show"
    Then I should be on Bar Cleo's detail page

  Scenario: Edit location
    Given a location exists with name: "Bar Cleo"
    And I am on the index of locations
    When I follow "Edit"
    Then I should be on Bar Cleo's edit page

  Scenario: Search by name
    Given the following locations exist
      | name  |
      | Cleo  |
      | Sassy |
    When I go to the index of locations
    And I fill in "Name" with "Cleo"
    Then I should see "Bar Cleo"
    And I should not see "Sassy"
