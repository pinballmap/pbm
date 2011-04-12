Feature: high roller list for region
  In order to make high scoring players feel pretty good about their scores
  As a guest
  I want to see these high scores

  Scenario: intro text display correct number of locations and machines for a region
    Given there is a region with the name "portland"
    And there is a region with the name "chicago"
    And the following users exist:
      |id|initials|
      |1|asc|
      |2|fsa|
      |3|jhm|
      |4|mcu|
      |5|pak|
      |6|rcb|
      |7|rtgt|
      |8|rxc|
      |9|ssw|
      |10|xxx|
      |11|yyy|
      |12|zzz|
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
      |location_machine_xref_id|score|user_id|rank|
      |1|100|9|1|
      |2|200|9|1|
      |1|90|7|2|
      |1|80|3|3|
      |1|70|1|4|
      |2|90|4|2|
      |2|80|6|3|
      |2|70|8|4|
      |1|50|2|5|
      |1|40|5|6|
      |1|20|10|6|
      |1|20|11|6|
      |1|20|12|6|
      |3|1|9|1|
    And I am on "Portland"'s high rollers page
    Then I should see "ssw: with 2 scores"
    And I should see "rtgt: with 1 scores"
    And I should not see "rcb: with 1 scores"
