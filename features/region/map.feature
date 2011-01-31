Feature: Map map
  In order to get some useful map area information
  As a guest
  I want to check out the map area information

  Scenario: display current high scores
    Given there is a location machine xref
    And a high score exists for location "Test Location Name"'s "Test Machine Name" with initials "ssw" and score "1234" and rank "GC"
    And I am on "Portland"'s home page
    Then I should see "Test Location Name's Test Machine Name: GC with 1234 by ssw"
