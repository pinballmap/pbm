Feature: high roller list for region
  In order to make high scoring players feel pretty good about their scores
  As a guest
  I want to see these high scores

  Scenario: intro text display correct number of locations and machines for a region
    Given there is a region with the name "portland"
    And there is a region with the name "chicago"
    And the following locations exist:
      |name|region|
      |cleo|name: portland|
      |sassy|name: portland|
      |bawb|name: chicago|
    And there is a machine with the name "zelda"
    And the following location machine xrefs exist:
      |id|location|machine|
      |1|name: cleo|name: zelda|
      |2|name: sassy|name: zelda|
      |3|name: bawb|name: zelda|
    And the following machine_score_xrefs exist:
      |location_machine_xref_id|score|initials|rank|
      |1|100|ssw|1|
      |2|200|ssw|1|
      |1|90|rtgt|2|
      |1|80|jhm|3|
      |1|70|asc|4|
      |2|90|mcu|2|
      |2|80|rcb|3|
      |2|70|rxc|4|
      |1|50|fsa|5|
      |1|40|pak|6|
      |1|20|xxx|6|
      |1|20|yyy|6|
      |1|20|zzz|6|
      |3|1|ssw|1|
    And I am on "Portland"'s high rollers page
    Then I should see "ssw: with 2 scores"
    And I should see "rtgt: with 1 scores"
    And I should not see "mcu: with 1 scores"
