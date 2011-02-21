Feature: Autocomplete
  In order to test autocomplete functionality
  As a guest
  I want to test autocomplete functionality

  @javascript
  Scenario: Add by machine name from input with autocomplete
    Given there is a location machine xref
    And the following machines exist:
      |name|
      |Sassy Madness|
      |Sassy From The Black Lagoon|
      |Cleo Game|
    And I am on "Portland"'s home page
    And I press the "location" search button
    And I click to see the detail for "Test Location Name"
    And I click on the add machine link for "Test Location Name"
    And I fill in "add_machine_by_name" with "Sassy"
    And I wait for 1 second
    Then I should see the following autocomplete options:
      |Sassy Madness|
      |Sassy From The Black Lagoon|

  @javascript
  Scenario: Search by machine name from input with autocomplete
    Given there is a location machine xref
    And the following machines exist:
      |name|
      |Sassy Madness|
      |Sassy From The Black Lagoon|
      |Cleo Game|
    And I am on "Portland"'s home page
    And I click to search by "machine"
    And I fill in "by_machine_name" with "Sassy"
    And I wait for 1 second
    Then I should see the following autocomplete options:
      |Sassy Madness|
      |Sassy From The Black Lagoon|

  @javascript
  Scenario: Search by location name from input with autocomplete
    Given there is a region with the name "portland"
    And the following locations exist:
      |name|
      |Cleo North|
      |Cleo South|
      |Sassy|
    And I am on "Portland"'s home page
    And I fill in "by_location_name" with "Cleo"
    And I wait for 1 second
    Then I should see the following autocomplete options:
      |Cleo North|
      |Cleo South|
