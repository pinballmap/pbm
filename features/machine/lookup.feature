Feature: Lookup machines
  In order to check out some machines
  As a guest
  I want to lookup machines

  Scenario: machines List
    Given a machine exists with name: "Cleo Tales"
    And I am on the machines page
    Then I should see "Cleo Tales"

  Scenario: Pagination
    Given there are 51 machines
    And a machine exists with name: "Cleo Tales"
    When I go to the machines page
    Then I should not see "Cleo Tales"

  Scenario: New machine
    Given I am on the machines page
    When I follow "New Machine"
    Then I should be on the new machine page

  Scenario: Show machine
    Given a machine exists with name: "Cleo Tales"
    And I am on the machines page
    When I follow "Show"
    Then I should be on the machine detail page for "Cleo Tales"

  Scenario: Edit machine
    Given a machine exists with name: "Cleo Tales"
    And I am on the machines page
    When I follow "Edit"
    Then I should be on the machine edit page for "Cleo Tales"

  Scenario: Delete machine
    Given a machine exists with name: "Cleo Tales"
    And I am on the machines page
    When I follow "Destroy"
    Then I should be on the machines page
    And I should see "Machine was successfully destroyed."

  Scenario: Search by name
    Given the following machines exist
      | name  |
      | Cleo  |
      | Sassy |
    When I go to the machines page
    And I fill in "Name" with "Cleo"
    And I press "Search"
    Then I should see "Cleo"
    And I should not see "Sassy"
