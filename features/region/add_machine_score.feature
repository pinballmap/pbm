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
    And I click on the add scores link for "Test Location Name"
    And I fill in a score with initials "ssw" and score "1234" and rank "GC"
    And I wait for 1 seconds
    And I press "add_score"
    And I wait for 1 seconds
    Then "Test Location Name"'s "Test Machine Name" should have a score with initials "ssw" and score "1234" and rank "1"
