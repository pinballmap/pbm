Feature: Location feeds
  In order to show users recent additions to the system
  As a guest
  I want to be able to get an xml feed of recent additions to the system

  @javascript
  Scenario: Add machine by name
    Given there is a region with the name "portland" with the id "1"
    And the following locations exist:
    |id|name|region_id|
    |1|Bawb|1|
    |2|Zelda|1|
    And the following machines exist:
    |id|name|
    |1|Sass|
    And the following location machine xrefs exist:
    |id|location_id|machine_id|
    |1|2|1|
    |2|1|1|
    |3|1|1|
    |4|1|1|
    |5|1|1|
    |6|1|1|
    |7|1|1|
    |8|1|1|
    |9|1|1|
    |10|1|1|
    |11|1|1|
    |12|1|1|
    |13|1|1|
    |14|1|1|
    |15|1|1|
    |16|1|1|
    |17|1|1|
    |18|1|1|
    |19|1|1|
    |20|1|1|
    |21|1|1|
    |22|1|1|
    |23|1|1|
    |24|1|1|
    |25|1|1|
    |26|1|1|
    |27|1|1|
    |28|1|1|
    |29|1|1|
    |30|1|1|
    |31|1|1|
    |32|1|1|
    |33|1|1|
    |34|1|1|
    |35|1|1|
    |36|1|1|
    |37|1|1|
    |38|1|1|
    |39|1|1|
    |40|1|1|
    |41|1|1|
    |42|1|1|
    |43|1|1|
    |44|1|1|
    |45|1|1|
    |46|1|1|
    |47|1|1|
    |48|1|1|
    |49|1|1|
    |50|1|1|
    |51|1|1|
    And I am on "portland"'s location feed page
    And I press the "location" search button
    Then I should not see "Zelda"
    And I should see "Bawb"
