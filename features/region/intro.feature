Feature: intro text for the site
  In order to tell the user how awesome this site is going to be
  As a guest
  I want to check out the intro text

  Scenario: intro text display correct number of locations and machines for a region
    Given the following regions exist:
      |name|id|
      |chicago|1|
      |portland|2|
    And the following locations exist:
      |name|region_id|id|
      |sassers|2|1|
      |bawb|2|2|
      |not a cat|1|3|
    And the following machines exist:
      |name|id|
      |cleo|1|
      |zelda|2|
    And the following location machine xrefs exist:
      |location_id|machine_id|
      |1|1|
      |1|2|
      |2|1|
      |3|1|
    And I am on "Portland"'s home page
    Then I should see "2 locations and 3 machines"
