Feature: show high scores for a machine
  In order to show high scores for machines
  As a guest
  I want to be able to take a look at these fine high scores

  @javascript
  Scenario: Don't show the "show high scores" option if there are no high scores
    Given there is a location machine xref
    And I am on "Portland"'s home page
    And I press the "location" search button
    Then I should not see the show scores option for "Test Location Name"'s "Test Machine Name"

  @javascript
  Scenario: Show the "show high scores" option if you just made a new machine, and there were previously no machines
    Given I am a logged in user
    And there is a location machine xref
    And I am on "Portland"'s home page
    And I press the "location" search button
    Then I should not see the show scores option for "Test Location Name"'s "Test Machine Name"
    Given I click on the add scores link for "Test Location Name"
    And I fill in a score of "1234" and rank "GC"
    And I press "add_score"
    Then I should see the show scores option for "Test Location Name"'s "Test Machine Name"
