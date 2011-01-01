Feature: New Machine for Location
  In order to add machines to locations
  As a guest
  I want to be able to add machines to locations

  Scenario: Add machine by name
    Given "Cleo" is a location with the name "Bar Cleo" and the lat "12.12" and the lon "44.44" and the id "1"
    And the following machines exist:
    |name|id|
    |Star Wars|1|
    |Medieval Madness|2|
    And I am on the home page
    And I select "Bar Cleo" from "by_location_id"
    And I press "Search"
    And I follow "show_location_detail_1"
    And I fill in "Machine Name" with "Star Wars"
    And I press "Add"
    Then location_machine_xref should exist with location_id: "1", machine_id: "1"

  Scenario: Add machine by id
    Given "Cleo" is a location with the name "Bar Cleo" and the lat "12.12" and the lon "44.44" and the id "1"
    And the following machines exist:
    |name|id|
    |Star Wars|1|
    |Medieval Madness|2|
    And I am on the home page
    And I select "Bar Cleo" from "by_location_id"
    And I press "Search"
    And I follow "show_location_detail_1"
    And I select "Medieval Madness" from "add_machine_by_id"
    And I press "Add"
    Then location_machine_xref should exist with location_id: "1", machine_id: "2"
