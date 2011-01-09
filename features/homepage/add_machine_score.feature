Feature: add a high score for a machine
  In order to add high scores to machines
  As a guest
  I want to be able to add high scores to machines

  @javascript
  Scenario: Add a new high score to a machine
    Given "Cleo" is a location with the name "Bar Cleo" and the lat "12.12" and the lon "44.44" and the id "1"
    And "SW" is a machine with the name "Star Wars"
    And there is a location machine xref with the location "Cleo" and the machine "SW"
    And I am on the home page
    And I press "Search"
    And I follow "Bar Cleo | 123 Pine | Portland"
    And I fill in "score" with "1234"
    And I select "GC" from "rank"
    And I fill in "initials" with "ssw"
    And I press "Add Score"
    Then "Bar Cleo"'s "Star Wars" should have a score with initials "ssw" and score "1234" and rank "1"
