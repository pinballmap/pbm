Feature: links for region
  In order to show users region-centric links
  As a guest
  I want to see these links

  Scenario: basic link showing
    Given there is a region with the name "portland"
    And there is a region with the name "chicago"
    And the following region link xref exist:
      |region|name|category|description|
      |name: portland|pdx link 1|main links||
      |name: portland|pdx link 2|main links||
      |name: portland|pdx link 3|main links||
      |name: portland|cool link 1|cool links||
      |name: chicago|cool link 2|cool links||
    And I am on "Portland"'s links page
    Then I should see "main links pdx link 1 pdx link 2 pdx link 3 cool links cool link 1"
