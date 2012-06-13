Feature: high roller list for region
  In order to make high scoring players feel pretty good about their scores
  As a guest
  I want to see these high scores

  Scenario: intro text display correct number of locations and machines for a region
    Given the following regions exist:
      |name|id|
      |portland|2|
      |chicago|3|
    And the following locations exist:
      |name|region_id|id|
      |cleo|2|1|
      |sassy|2|2|
      |bawb|3|3|
    And there is a machine with the name "zelda" and the id "1"
    And the following location machine xrefs exist:
      |id|location_id|machine_id|
      |1|1|1|
      |2|2|1|
      |3|3|1|
    And the following machine_score_xrefs exist:
      |location_machine_xref_id|score|initials|rank|
      |1|100|ssw|1|
      |2|200|ssw|1|
      |1|90|rtgt|2|
    And I am on "Portland"'s high rollers page
    Then I should see "ssw: with 2 scores"
    And I should see "rtgt: with 1 scores"
