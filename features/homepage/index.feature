Feature: Main page
  In order to check out the cool dashboard
  As a guest
  I want to do look at the dashboard, properly

  Scenario: Homepage summaries show the proper number of locations and machines per region
    Given the following regions exist:
      |name|
      |chicago|
      |portland|
    And "chicago" has 5 locations and 10 machines
    And "portland" has 8 locations and 17 machines
    And I am on the home page
    Then I should see a summary for "5 locations" and "10 machines"
    And I should see a summary for "8 locations" and "17 machines"
