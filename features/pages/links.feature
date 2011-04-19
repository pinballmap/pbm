Feature: links for region
  In order to show users region-centric links
  As a guest
  I want to see these links

  Scenario: basic link showing
    Given there is a region with the name "portland"
    And there is a region with the name "chicago"
    And the following region link xref exist:
      |region|name|category|description|sort_order|
      |name: portland|pdx link 1|main links||2|
      |name: portland|pdx link 2|main links||2|
      |name: portland|pdx link 3|main links||2|
      |name: portland|cool link 1|cool links||1|
      |name: chicago|cool link 2|cool links||1|
    And I am on "Portland"'s links page
    Then I should see "cool links cool link 1 main links pdx link 1 pdx link 2 pdx link 3"
