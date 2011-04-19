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
    And I click on the add machine link for "Test Location Name"
    And I fill in "add_machine_by_name" with "sassy"
    Then I should see the following autocomplete options:
      |Sassy From The Black Lagoon|
      |Sassy Madness|

  @javascript
  Scenario: Search by machine name from input with autocomplete
    Given there is a location machine xref
    And the following machines exist:
      |name|
      |Sassy Madness|
      |Sassy From The Black Lagoon|
      |Cleo Game|
    And I am on "Portland"'s home page
    And I switch to "machine" lookup
    And I fill in "by_machine_name" with "sassy"
    Then I should see the following autocomplete options:
      |Sassy From The Black Lagoon|
      |Sassy Madness|

  @javascript
  Scenario: Search by location name from input with autocomplete
    Given there is a region with the name "portland"
    And the following regions exist:
      |name|
      |portland|
      |chicago|
    And the following locations exist:
      |name|region|
      |Cleo North|name: portland|
      |Cleo South|name: portland|
      |Sassy|name: portland|
      |Cleo East|name: chicago|
    And I am on "Portland"'s home page
    And I fill in "by_location_name" with "cleo"
    Then I should see the following autocomplete options:
      |Cleo North|
      |Cleo South|
    And I should not see the following autocomplete options:
      |Cleo East|
