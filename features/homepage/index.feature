Feature: Main page
  In order to do pretty much everything on this website
  As a guest
  I want to do basic site navigation

#  @javascript
#  Scenario: Search by location name from input with autocomplete
#    Given a location exists with name: "Bar Cleo", street: "123 pine", city: "Portland"
#    And the following locations exist
#      |name|
#      |Cleo North|
#      |Cleo South|
#      |Sassy|
#    And I am on the home page
#    When I fill in "Location Name" with "Sassy"
#    Then I should see the following autocomplete options
#      |Sassy North|
#      |Sassy South|
#    When I click "Sassy North" in the autocomplete options
#    And I press "Search"
#    Then I should see "Bar Cleo | 123 pine | Portland"

  Scenario: Search by location name from select
    Given "Bar Cleo" is a location with the name "Bar Cleo" and the street "123 pine" and the city "Portland"
    And "Star Wars" is a machine with the name "Star Wars"
    And there is a location machine xref with the location "Bar Cleo" and the machine "Star Wars"
    And I am on the home page
    And I select "Bar Cleo" from "location_select"
    And I press "Search"
    Then I should see "Bar Cleo | 123 pine | Portland | Star Wars"
