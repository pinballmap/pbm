Feature: suggest location for region
  In order to allow users to suggest locations
  As a guest
  I want to have a cool location suggestion form

  Scenario: state dropdown is limited to unique states within a region
    Given there is a region with the name "portland"
    And there is a region with the name "chicago"
    And the following locations exist:
      |name|region|state|
      |cleo|name: portland|OR|
      |sassy|name: portland|WA|
      |zelda|name: chicago|IL|
    And I am on "Portland"'s suggest new location page
    Then I should see "OR"
    And I should see "WA"
    And I should not see "IL"
