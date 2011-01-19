Feature: add a high score for a machine
  In order to add high scores to machines
  As a guest
  I want to be able to add high scores to machines

  @javascript
  Scenario: Add a new high score to a machine
    Given there is a location machine xref
    And I am on "Portland"'s home page
    And I press "Search"
    And I click to see the detail for "Test Location Name"
    And I click on the show machines link for "Test Location Name"
    And I fill in "score" with "1234"
    And I select "GC" from "rank"
    And I fill in "initials" with "ssw"
    And I press "Add Score"
    Then "Test Location Name"'s "Test Machine Name" should have a score with initials "ssw" and score "1234" and rank "1"
