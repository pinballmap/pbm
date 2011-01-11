Feature: Remove Machine for Location
  In order to remove machines from locations
  As a guest
  I want to be able to remove machines from locations

  @javascript
  Scenario: Remove machine from location
    Given there is a location machine xref
    And I am on "Portland"'s home page
    And I press "Search"
    And I follow "Test Location Name | 123 Pine | Portland"
    And I press "Remove"
    Then location_machine_xref should not exist
