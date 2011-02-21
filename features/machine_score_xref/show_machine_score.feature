Feature: show high scores for a machine
  In order to show high scores for machines
  As a guest
  I want to be able to take a look at these fine high scores

  @javascript
  Scenario: Don't show the "show high scores" option if there are no high scores
    Given there is a location machine xref
    And I am on "Portland"'s home page
    And I press the "location" search button
    And I click to see the detail for "Test Location Name"
    And I click on the show machines link for "Test Location Name"
    Then I should not see the show scores option for "Test Location Name"'s "Test Machine Name"

  @javascript
  Scenario: Show the "show high scores" option if you just made a new machine, and there were previously no machines
    Given there is a location machine xref
    And I am on "Portland"'s home page
    And I press the "location" search button
    And I click to see the detail for "Test Location Name"
    And I click on the show machines link for "Test Location Name"
    Then I should not see the show scores option for "Test Location Name"'s "Test Machine Name"
    Given I click on the add scores link for "Test Location Name"
    And I fill in a score with initials "ssw" and score "1234" and rank "GC"
    And I wait for 1 seconds
    And I press "add_score"
    And I wait for 1 seconds
    Then I should see the show scores option for "Test Location Name"'s "Test Machine Name"
