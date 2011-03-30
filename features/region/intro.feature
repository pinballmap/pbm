Feature: intro text for the site
  In order to tell the user how awesome this site is going to be
  As a guest
  I want to check out the intro text

  Scenario: intro text display correct number of locations and machines for a region
    Given the following regions exist:
      |name|
      |chicago|
      |portland|
    And the following locations exist:
      |name|region|
      |sassers|name: portland|
      |bawb|name: portland|
      |not a cat|name: chicago|
    And the following machines exist:
      |name|
      |cleo|
      |zelda|
    And the following location machine xrefs exist:
      |location|machine|
      |name: sassers|name: cleo|
      |name: sassers|name: zelda|
      |name: bawb|name: cleo|
      |name: not a cat|name: cleo|
    And I am on "Portland"'s home page
    Then I should see "2 locations and 3 machines"
