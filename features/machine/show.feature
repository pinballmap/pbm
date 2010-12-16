Feature: Show machines
  In order to scope out a machine
  As a guest
  I want to look at a machine

  Scenario: Show machine
    Given a machine exists with name: "Cleo Tales"
    And I am on the machine detail page for "Cleo Tales"
    Then I should see "Cleo Tales"

  Scenario: Back button
    Given a machine exists with name: "Cleo"
    And I am on the machine detail page for "Cleo"
    And I follow "Back"
    Then I should be on the machines page
