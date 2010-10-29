Feature: Lookup Locations
  In order to check out some locations
  As a guest
  I want to lookup locations

  Scenario: Locations List
    Given a location exists with a name of "Bar Cleo"
    When I go to the index of locations
    Then I should see "Bar Cleo"
