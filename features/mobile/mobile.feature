Feature: events for mobile apps
  In order to support mobile devices
  As a guest
  I want to interact with the website

  Scenario: defaults to portland region when no region is given
    Given the following regions exist:
      |id|name|
      |1|portland|
    And I go to the mobile page for "/iphone.html?init=1"
    Then I should be on the mobile page for "/portland/locations.xml"

  Scenario: respects region param
    Given the following regions exist:
      |id|name|
      |1|portland|
      |2|chicago|
    And I go to the mobile page for "/iphone.html?init=1;region=chicago"
    Then I should be on the mobile page for "/chicago/locations.xml"

  Scenario: respects all region data init param
    Given the following regions exist:
      |id|name|
      |1|portland|
      |2|chicago|
    And I go to the mobile page for "/iphone.html?init=5;region=chicago"
    Then I should be on the mobile page for "/chicago/all_region_data.json"

  Scenario: init=1
    Given the following regions exist:
      |id|name|
      |1|portland|
    And the following locations exist:
      |id|name|lat|lon|region_id|
      |1|Sasston|12|21|1|
    And the following zones exist:
      |id|name|
      |1|NE|
    And the following machines exist:
      |id|name|
      |1|Cleo's Adventure|
    And the following location machine xrefs exist:
      |location_id|machine_id|
      |1|1|
    And I go to the mobile page for "/iphone.html?init=1"
    Then I should be on the mobile page for "/portland/locations.xml"
    And I should see the following output:
      """
      <!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\" \"http://www.w3.org/TR/REC-html40/loose.dtd\">\n<?xml version=\"1.0\" encoding=\"UTF-8\"?><html><body><data><locations><location><id>1</id><name>Sasston</name><neighborhood></neighborhood><zoneno></zoneno><nummachines>1</nummachines><lat>12.0</lat><lon>21.0</lon></location></locations><machines><machine><id>1</id><name>Cleo's Adventure</name><numlocations>1</numlocations></machine></machines><zones></zones></data></body></html>
      """

  Scenario: 4sq export
    Given the following regions exist:
      |id|name|full_name|lat|lon|
      |1|portland|Portland|1|2|
      |2|chicago|Chicago|3|4|
    And the following locations exist:
      |id|name|lat|lon|street|city|state|zip|phone|region_id|
      |1|Foo|1|1|123 pine|portland|OR|97211|555-555-5555|1|
      |2|Bar|2|2|456 oak|chicago|IL|55555|123-456-7890|2|
    And the following machines exist:
      |id|name|
      |1|Cleo|
      |2|Satchmo|
    And the following location machine xrefs exist:
      |location_id|machine_id|
      |1|1|
      |1|2|
      |2|1|
    And I go to the mobile page for "/4sq_export.xml"
    And I should see the following output:
      """
    <!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\" \"http://www.w3.org/TR/REC-html40/loose.dtd\">\n<?xml version=\"1.0\" encoding=\"UTF-8\"?><html><body><data><regions><region><name>portland</name><fullname>Portland</fullname><lat>1.0</lat><lon>2.0</lon><locations><location><name>Foo</name><lat>1.0</lat><lon>1.0</lon><street>123 pine</street><city>portland</city><state>OR</state><zip>97211</zip><phone>555-555-5555</phone><nummachines>2</nummachines><machines><machine><name>Cleo</name></machine><machine><name>Satchmo</name></machine></machines></location></locations></region><region><name>chicago</name><fullname>Chicago</fullname><lat>3.0</lat><lon>4.0</lon><locations><location><name>Bar</name><lat>2.0</lat><lon>2.0</lon><street>456 oak</street><city>chicago</city><state>IL</state><zip>55555</zip><phone>123-456-7890</phone><nummachines>1</nummachines><machines><machine><name>Cleo</name></machine></machines></location></locations></region></regions></data></body></html>
      """

  Scenario: region init
    Given the following regions exist:
      |id|name|full_name|motd|lat|lon|n_search_no|
      |1|portland|Portland OR|This is a MOTD|12.1|-1.9|4|
      |2|bayarea|Bay Area||2.4|-4.9||
    And the following users exist:
      |id|email|region_id|
      |1|foo@bar.com|1|
    And I go to the mobile page for "/iphone.html?init=2"
    Then I should be on the mobile page for "/portland/regions.xml"
    And I should see the following output:
      """
      <!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\" \"http://www.w3.org/TR/REC-html40/loose.dtd\">\n<?xml version=\"1.0\" encoding=\"UTF-8\"?><html><body><data><regions><region><id>1</id><name>portland</name><formalname>Portland OR</formalname><subdir>portland</subdir><lat>12.1</lat><lon>-1.9</lon><nsearchno>4</nsearchno><motd>This is a MOTD</motd><emailcontact>foo@bar.com</emailcontact></region><region><id>2</id><name>bayarea</name><formalname>Bay Area</formalname><subdir>bayarea</subdir><lat>2.4</lat><lon>-4.9</lon><nsearchno></nsearchno><motd></motd><emailcontact>email_not_found@noemailfound.noemail</emailcontact></region></regions></data></body></html>
      """

  Scenario: location detail
    Given the following regions exist:
      |id|name|
      |1|portland|
    And the following locations exist:
      |id|name|lat|lon|region_id|
      |1|Sasston|12|21|1|
    And the following machines exist:
      |id|name|
      |1|Cleo's Adventure|
    And the following location machine xrefs exist:
      |location_id|machine_id|
      |1|1|
    And I go to the mobile page for "/iphone.html?get_location=1"
    Then I should be on the mobile page for "/portland/locations/1.xml"
    And I should see the following output:
      """
      <!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\" \"http://www.w3.org/TR/REC-html40/loose.dtd\">\n<?xml version=\"1.0\" encoding=\"UTF-8\"?><html><body><data><locations><location><id>1</id><name>Sasston</name><zoneno></zoneno><zone></zone><neighborhood></neighborhood><lat>12.0</lat><lon>21.0</lon><street1>303 Southeast 3rd Avenue</street1><street2></street2><city>Portland</city><state>OR</state><zip>97214</zip><phone></phone><nummachines>1</nummachines><machines><machine><id>1</id><name>Cleo's Adventure</name></machine></machines></location></locations></data></body></html>
      """

  Scenario: locations for machine
    Given the following regions exist:
      |id|name|
      |1|portland|
    And the following locations exist:
      |id|region_id|name|
      |1|1|Sasston|
      |2|1|Cleoville|
      |3|1|Bawbston|
    And the following machines exist:
      |id|name|
      |1|Cleo's Adventure|
    And the following location machine xrefs exist:
      |location_id|machine_id|
      |1|1|
      |2|1|
    And I go to the mobile page for "/iphone.html?get_machine=1"
    Then I should be on the mobile page for "/portland/locations/1/locations_for_machine.xml"
    And I should see the following output:
      """
      <!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\" \"http://www.w3.org/TR/REC-html40/loose.dtd\">\n<?xml version=\"1.0\" encoding=\"UTF-8\"?><html><body><data><locations><location><id>2</id><name>Cleoville</name><zoneno></zoneno><zone></zone><neighborhood></neighborhood><lat></lat><lon></lon><street1>303 Southeast 3rd Avenue</street1><street2></street2><city>Portland</city><state>OR</state><zip>97214</zip><phone></phone><nummachines>1</nummachines></location><location><id>1</id><name>Sasston</name><zoneno></zoneno><zone></zone><neighborhood></neighborhood><lat></lat><lon></lon><street1>303 Southeast 3rd Avenue</street1><street2></street2><city>Portland</city><state>OR</state><zip>97214</zip><phone></phone><nummachines>1</nummachines></location></locations></data></body></html>
      """

  Scenario: update conditions
    Given the following regions exist:
      |id|name|
      |1|portland|
    And the following locations exist:
      |id|region_id|name|
      |1|1|Sasston|
    And the following machines exist:
      |id|name|
      |1|Cleo's Adventure|
    And the following location machine xrefs exist:
      |id|location_id|machine_id|condition|
      |1|1|1|foo|
    And I go to the mobile page for "/iphone.html?condition=bar;location_no=1;machine_no=1"
    Then I should be on the mobile page for "/portland/location_machine_xrefs/1/condition_update_confirmation.xml"
    And I should see the following output:
      """
      <!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\" \"http://www.w3.org/TR/REC-html40/loose.dtd\">\n<?xml version=\"1.0\" encoding=\"UTF-8\"?><html><body><data><msg>add successful</msg></data></body></html>
      """

  Scenario: modify location, add existing machine by machine_no
    Given the following regions exist:
      |id|name|
      |1|portland|
    And the following locations exist:
      |id|region_id|name|
      |1|1|Sasston|
    And the following machines exist:
      |id|name|
      |1|Cleo's Adventure|
      |2|Bawb's Adventure|
    And I go to the mobile page for "/iphone.html?modify_location=1;machine_no=2"
    And "Sasston" should have "Bawb's Adventure"
    And I should see the following output:
      """
      <!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\" \"http://www.w3.org/TR/REC-html40/loose.dtd\">\n<?xml version=\"1.0\" encoding=\"UTF-8\"?><html><body><data><msg>
      add successful
      </msg><id>
      2
      </id></data></body></html>
      """

  Scenario: modify location, add existing machine by machine_name
    Given the following regions exist:
      |id|name|
      |1|portland|
    And the following locations exist:
      |id|region_id|name|
      |1|1|Sasston|
    And the following machines exist:
      |id|name|
      |1|Cleo|
      |2|Bawb's Adventure|
    And I go to the mobile page for "/iphone.html?modify_location=1;machine_name=Cleo"
    And "Sasston" should have "Cleo"
    And I should see the following output:
      """
      <!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\" \"http://www.w3.org/TR/REC-html40/loose.dtd\">\n<?xml version=\"1.0\" encoding=\"UTF-8\"?><html><body><data><msg>
      add successful
      </msg><id>
      1
      </id></data></body></html>
      """

  Scenario: modify location, add machine that isn't in the system
    Given the following regions exist:
      |id|name|
      |1|portland|
    And the following locations exist:
      |id|region_id|name|
      |1|1|Sasston|
    And the following machines exist:
      |id|name|
      |2|Cleo's Adventure|
    And I go to the mobile page for "/iphone.html?modify_location=1;machine_name=Satchmo"
    And "Sasston" should have "Satchmo"

  Scenario: modify location, remove machine
    Given the following regions exist:
      |id|name|
      |1|portland|
    And the following locations exist:
      |id|region_id|name|
      |1|1|Sasston|
    And the following machines exist:
      |id|name|
      |1|Cleo's Adventure|
    And the following location machine xrefs exist:
      |id|location_id|machine_id|
      |1|1|1|
    And I go to the mobile page for "/iphone.html?modify_location=1;machine_no=1"
    Then I should be on the mobile page for "/portland/location_machine_xrefs/1/remove_confirmation.xml"
    And location_machine_xref should not exist
    And I should see the following output:
      """
      <!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\" \"http://www.w3.org/TR/REC-html40/loose.dtd\">\n<?xml version=\"1.0\" encoding=\"UTF-8\"?><html><body><data><msg>remove successful</msg></data></body></html>
      """
