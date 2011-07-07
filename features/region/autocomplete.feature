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
    And the following locations exist:
      |name|region|
      |Bawb|name: portland|
    And the following machines exist:
      |name|
      |Cleo|
      |Another Test Machine|
    And the following location machine xrefs exist:
      |location|machine|
      |name: Bawb|name: Another Test Machine|
    And I am on "Portland"'s home page
    And I switch to "machine" lookup
    And I fill in "by_machine_name" with "test"
    Then I should see the following autocomplete options:
      |Another Test Machine|
      |Test Machine Name|

  @javascript
  Scenario: Search by location name from input with autocomplete
    Given the following regions exist:
      |id|name|
      |1|portland|
      |2|chicago|
    And the following locations exist:
      |name|region_id|
      |Cleo North|1|
      |Cleo South|1|
      |Sassy|1|
      |Cleo East|2|
    And I am on "portland"'s home page
    And I fill in "by_location_name" with "cleo"
    Then I should see the following autocomplete options:
      |Cleo North|
      |Cleo South|
    And I should not see the following autocomplete options:
      |Cleo East|
      |Sassy|
