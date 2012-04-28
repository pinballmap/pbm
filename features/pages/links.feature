Feature: links for region
  In order to show users region-centric links
  As a guest
  I want to see these links

  Scenario: basic link showing
    Given the following regions exist:
      |id|name|
      |1|portland|
      |2|chicago|
    And the following region link xrefs exist:
      |region_id|name|category|description|sort_order|
      |2|pdx link 1|main links||2|
      |2|pdx link 2|main links||2|
      |2|pdx link 3|main links||2|
      |2|cool link 1|cool links||1|
      |1|cool link 2|cool links||1|
    And I am on "chicago"'s links page
    Then I should see "cool links cool link 1 main links pdx link 1 pdx link 2 pdx link 3"
