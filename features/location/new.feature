Feature: New Locations
  In order to create a new location
  As a guest
  I want to create locations

  Scenario: Locations List
    Given I am on the new_location page
    And I fill in the following:
      |Location Name|Cleo    |
      |Street|123 Pine|
      |City|Portland|
      |State|OR      |
      |Zip|97211   |
    And I press "Create Location"
    Then I should be on the location detail page for "Cleo"
    And a location should exist with name: "Cleo"

  Scenario: Required fields not filled in
    Given I am on the new_location page
    And I press "Create Location"
    Then I should be on the locations page
    And I should see "can't be blank"
