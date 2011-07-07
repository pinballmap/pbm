Feature: events for region
  In order to show users events
  As a guest
  I want to see these events

  Scenario: basic event displaying
    Given the following regions exist:
      |id|name|
      |1|portland|
    And the following locations exist:
      |id|region_id|
      |1|1|
    And the following events exist:
      |region_id|name|start_date|location_id|
      |1|event 1|2011-01-20|1|
      |1|event 2|2011-01-30|1|
      |1|event 3|2011-01-10|1|
    And I am on "portland"'s events page
    Then I should see "2011-01-10 : event 3 @ Test Location Name 2011-01-20 : event 1 @ Test Location Name 2011-01-30 : event 2 @ Test Location Name"
