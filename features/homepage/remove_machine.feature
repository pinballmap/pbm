Feature: Remove Machine for Location
  In order to remove machines from locations
  As a guest
  I want to be able to remove machines from locations

  @javascript
  Scenario: Remove machine from location
    Given there is a location machine xref
    And I am on "Portland"'s home page
    And I press "Search"
    And I click to see the detail for "Test Location Name"
    And I click on the show machines link for "Test Location Name"
    And I press "Remove"
    Then location_machine_xref should not exist
