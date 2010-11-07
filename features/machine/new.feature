Feature: New machines
  In order to create a new machine
  As a guest
  I want to create machines

  Scenario: machines List
    Given I am on the new_machine page
    And I fill in "Name" with "Cleo"
    And I press "Create Machine"
    Then I should be on the machine detail page for "Cleo"
    And a machine should exist with name: "Cleo"

  Scenario: Required fields not filled in
    Given I am on the new_machine page
    And I press "Create Machine"
    Then I should be on the machines page
    And I should see "can't be blank"
