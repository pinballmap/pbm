Feature: Edit machines
  In order to edit a machine
  As a guest
  I want to edit the machine

  Scenario: Edit name
    Given a machine exists with name: "Cleo Tales"
    And I am on the machine edit page for "Cleo Tales"
    And I fill in "Machine Name" with "Sass"
    And I press "Update Machine"
    Then I should be on the machine detail page for "Sass"
    And I should see "Sass"
    And I should not see "Cleo Tales"

  Scenario: Back button
    Given a machine exists with name: "Cleo Tales"
    And I am on the machine edit page for "Cleo Tales"
    And I follow "Back"
    Then I should be on the machines page
