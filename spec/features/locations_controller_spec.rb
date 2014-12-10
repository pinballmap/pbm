require 'spec_helper'

describe LocationsController do
  before(:each) do
    @region = FactoryGirl.create(:region, name: 'portland', full_name: 'portland', lat: 1, lon: 2, motd: 'This is a MOTD', n_search_no: 4, should_email_machine_removal: 1)
  end

  describe 'remove machine', type: :feature, js: true do
    before(:each) do
      @location = FactoryGirl.create(:location, region_id: @region.id, name: 'Cleo')
      @machine = FactoryGirl.create(:machine, name: 'Bawb')
    end

    def handle_js_confirm
      page.evaluate_script 'window.confirmMsg = null'
      page.evaluate_script 'window.confirm = function(msg) { window.confirmMsg = msg; return true; }'
      yield
      page.evaluate_script 'window.confirmMsg'
    end

    it 'removes a machine from a location' do
      FactoryGirl.create(:location_machine_xref, location: @location, machine: @machine)

      page.driver.headers = { 'User-Agent' => 'Mozilla/5.0 (cleOS)' }

      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          body: "Cleo\nBawb\nportland\n(entered from 127.0.0.1 via Mozilla/5.0 (cleOS))",
          subject: 'PBM - Someone removed a machine from a location',
          to: [],
          from: 'admin@pinballmap.com'
        )
      end

      visit '/portland/?by_location_id=' + @location.id.to_s

      handle_js_confirm do
        click_button 'remove'
      end

      sleep 1

      expect(LocationMachineXref.all).to eq([])
    end

    it 'removes a machine from a location - allows you to cancel out of remove' do
      lmx = FactoryGirl.create(:location_machine_xref, location: @location, machine: @machine)

      expect(Pony).to_not receive(:mail)

      visit '/portland/?by_location_id=' + @location.id.to_s

      handle_js_confirm do
        click_button 'remove'
      end

      sleep 1

      expect(LocationMachineXref.all).to eq([lmx])
    end
  end

  describe 'initial search by passed in param', type: :feature, js: true do
    before(:each) do
      @type = FactoryGirl.create(:location_type, name: 'Bar')
      @zone = FactoryGirl.create(:zone, region: @region, name: 'DT')
      @location = FactoryGirl.create(:location, region: @region, city: 'Portland', name: 'Cleo', zone: @zone, location_type: @type)
      @machine = FactoryGirl.create(:machine, name: 'Barb')
      FactoryGirl.create(:location_machine_xref, location: @location, machine: @machine)

      FactoryGirl.create(:location, region: @region, name: 'Sass', city: 'Beaverton')
    end

    it 'by_city_id' do
      visit '/portland/?by_city_id=' + @location.city

      expect(page).to have_content('Cleo')
      expect(page).to_not have_content('Sass')
    end

    it 'by_location_id' do
      visit '/portland/?by_location_id=' + @location.id.to_s

      expect(page).to have_content('Cleo')
      expect(page).to_not have_content('Sass')
    end

    it 'by_location_id -- multiple ids' do
      other_location = FactoryGirl.create(:location, region: @region, name: 'Zelda')

      visit '/portland/?by_location_id=' + @location.id.to_s + '_' + other_location.id.to_s

      expect(page).to have_content('Cleo')
      expect(page).to have_content('Zelda')
      expect(page).to_not have_content('Sass')
    end

    it 'by_zone_id' do
      visit '/portland/?by_zone_id=' + @zone.id.to_s

      expect(page).to have_content('Cleo')
      expect(page).to_not have_content('Sass')
    end

    it 'by_zone_id -- multiple ids' do
      other_zone = FactoryGirl.create(:zone, name: 'NE')
      FactoryGirl.create(:location, region: @region, name: 'Zelda', zone: other_zone)
      visit '/portland/?by_zone_id=' + @zone.id.to_s + '_' + other_zone.id.to_s

      expect(page).to have_content('Cleo')
      expect(page).to have_content('Zelda')
      expect(page).to_not have_content('Sass')
    end

    it 'by_type_id' do
      visit '/portland/?by_location_type_id=' + @type.id.to_s

      expect(page).to have_content('Cleo')
      expect(page).to_not have_content('Sass')
    end

    it 'by_type_id -- multiple ids' do
      other_type = FactoryGirl.create(:location_type, name: 'PUB')
      FactoryGirl.create(:location, region: @region, name: 'Zelda', location_type: other_type)

      visit '/portland/?by_location_type_id=' + @type.id.to_s + '_' + other_type.id.to_s

      expect(page).to have_content('Cleo')
      expect(page).to have_content('Zelda')
      expect(page).to_not have_content('Sass')
    end

    it 'by_machine_id' do
      visit '/portland/?by_machine_id=' + @machine.id.to_s

      expect(page).to have_content('Cleo')
      expect(page).to_not have_content('Sass')
    end

    it 'by_machine_id -- multiple ids' do
      other_machine = FactoryGirl.create(:machine, name: 'Cool')
      other_location = FactoryGirl.create(:location, region: @region, name: 'Zelda')
      FactoryGirl.create(:location_machine_xref, location: other_location, machine: other_machine)

      visit '/portland/?by_machine_id=' + @machine.id.to_s + '_' + other_machine.id.to_s

      expect(page).to have_content('Cleo')
      expect(page).to have_content('Zelda')
      expect(page).to_not have_content('Sass')
    end
  end

  describe 'update_desc', type: :feature, js: true do
    before(:each) do
      @location = FactoryGirl.create(:location, region: @region, name: 'Cleo')
    end

    it 'does not save spam' do
      stub_const('ENV', 'RAKISMET_KEY' => 'asdf')

      expect(Rakismet).to receive(:akismet_call).and_return('true')

      visit '/portland/?by_location_id=' + @location.id.to_s

      find("#desc_show_location_#{@location.id}").click
      fill_in("new_desc_#{@location.id}", with: 'THIS IS SPAM')
      click_on 'Save'

      sleep 1

      expect(Location.find(@location.id).description).to eq(nil)
    end

    it 'allows users to update a location description - stubbed out spam detection' do
      stub_const('ENV', 'RAKISMET_KEY' => 'asdf')

      expect(Rakismet).to receive(:akismet_call).and_return('false')

      visit '/portland/?by_location_id=' + @location.id.to_s

      find("#desc_show_location_#{@location.id}").click
      fill_in("new_desc_#{@location.id}", with: 'COOL DESC')
      click_on 'Save'

      sleep 1

      expect(Location.find(@location.id).description).to eq('COOL DESC')
    end

    it 'allows users to update a location description - skips validation' do
      @location.phone = '555'
      @location.save(validate: false)

      visit '/portland/?by_location_id=' + @location.id.to_s

      find("#desc_show_location_#{@location.id}").click
      fill_in("new_desc_#{@location.id}", with: 'COOL DESC')
      click_on 'Save'

      sleep 1

      expect(Location.find(@location.id).description).to eq('COOL DESC')
    end
  end

  describe 'mobile', type: :feature, js: true do

    it 'defaults to portland if no region is given' do
      visit '/iphone.html?init=1'

      expect(current_url).to match(%r{\/portland\/locations.xml})
    end

    it 'honors region param' do
      FactoryGirl.create(:region, name: 'toronto')

      visit '/iphone.html?init=1;region=toronto'

      expect(current_url).to match(%r{\/toronto\/locations.xml})
    end

    it 'takes an optional format parameter' do
      FactoryGirl.create(:region, name: 'toronto')

      visit '/iphone.html?init=1;region=toronto;format=json'

      expect(current_url).to match(%r{\/toronto\/locations.json})
    end

    it 'respects all region data init param' do
      FactoryGirl.create(:region, name: 'toronto')

      visit '/iphone.html?init=5;region=toronto'

      expect(current_url).to match(%r{\/toronto\/all_region_data.json})
    end

    it 'handles init=1' do
      location = FactoryGirl.create(:location, region: @region, name: 'Sasston', lat: 12, lon: 21)
      FactoryGirl.create(:zone, region: @region, name: 'NE')
      machine = FactoryGirl.create(:machine, name: 'Batman')
      FactoryGirl.create(:location_machine_xref, location: location, machine: machine)

      visit '/iphone.html?init=1'

      expect(current_url).to match(%r{\/portland\/locations.xml})

      page_contents = <<XML
<data>
    <locations>
        <location>
            <id>1</id>
            <name>Sasston</name>
            <neighborhood/>
            <zoneNo/>
            <numMachines>1</numMachines>
            <lat>12.0</lat>
            <lon>21.0</lon>
        </location>
    </locations>
    <machines>
        <machine>
            <id>1</id>
            <name>Batman</name>
            <numLocations>1</numLocations>
        </machine>
    </machines>
    <zones>
      <zone>
        <id>1</id>
        <name>NE</name>
        <shortName/>
        <isPrimary>0</isPrimary>
      </zone>
    </zones>
</data>
XML
      expect(page.html.gsub(/\s/, '').downcase).to include(page_contents.gsub(/\s/, '').downcase)
    end

    it 'works for 4sq' do
      toronto = FactoryGirl.create(:region, name: 'toronto', full_name: 'toronto', lat: 3, lon: 4)
      bawb_location = FactoryGirl.create(:location, name: 'Bawb', lat: 1, lon: 1, street: '123 pine', city: 'portland', state: 'OR', zip: '97211', phone: '555-555-5555', region: @region)
      cleo_location = FactoryGirl.create(:location, name: 'Cleo', lat: 2, lon: 2, street: '456 oak', city: 'toronto', state: 'IL', zip: '55555', phone: '123-456-7890', region: toronto)
      spiderman = FactoryGirl.create(:machine, name: 'Spider-Man')
      batman = FactoryGirl.create(:machine, name: 'Batman')
      FactoryGirl.create(:location_machine_xref, location: bawb_location, machine: spiderman)
      FactoryGirl.create(:location_machine_xref, location: bawb_location, machine: batman)
      FactoryGirl.create(:location_machine_xref, location: cleo_location, machine: spiderman)

      visit '/4sq_export.xml'

      page_contents = <<XML
<data>
    <regions>
        <region>
            <name>portland</name>
            <fullName>Portland</fullName>
            <lat>1.0</lat>
            <lon>2.0</lon>
            <locations>
                <location>
                    <name>Bawb</name>
                    <lat>1.0</lat>
                    <lon>1.0</lon>
                    <street>123 pine</street>
                    <city>portland</city>
                    <state>OR</state>
                    <zip>97211</zip>
                    <phone>555-555-5555</phone>
                    <numMachines>2</numMachines>
                    <machines>
                        <machine>
                            <name>Batman</name>
                        </machine>
                        <machine>
                            <name>Spider-Man</name>
                        </machine>
                    </machines>
                </location>
            </locations>
        </region>
        <region>
            <name>toronto</name>
            <fullName>toronto</fullName>
            <lat>3.0</lat>
            <lon>4.0</lon>
            <locations>
                <location>
                    <name>Cleo</name>
                    <lat>2.0</lat>
                    <lon>2.0</lon>
                    <street>456 oak</street>
                    <city>toronto</city>
                    <state>IL</state>
                    <zip>55555</zip>
                    <phone>123-456-7890</phone>
                    <numMachines>1</numMachines>
                    <machines>
                        <machine>
                            <name>Spider-Man</name>
                        </machine>
                    </machines>
                </location>
            </locations>
        </region>
    </regions>
</data>
XML
      expect(page.html.gsub(/\s/, '').downcase).to include(page_contents.gsub(/\s/, '').downcase)
    end

    it 'region initialization' do
      FactoryGirl.create(:region, name: 'bayarea', full_name: 'Bay Area', lat: 3, lon: 4)
      FactoryGirl.create(:user, email: 'foo@bar.com', region: @region)

      visit '/iphone.html?init=2'

      page_contents = <<XML
<data>
    <regions>
        <region>
            <id>1</id>
            <name>portland</name>
            <formalName>Portland</formalName>
            <subdir>portland</subdir>
            <lat>1.0</lat>
            <lon>2.0</lon>
            <nSearchNo>4</nSearchNo>
            <motd>This is a MOTD</motd>
            <emailContact>foo@bar.com</emailContact>
        </region>
        <region>
            <id>2</id>
            <name>bayarea</name>
            <formalName>Bay Area</formalName>
            <subdir>bayarea</subdir>
            <lat>3.0</lat>
            <lon>4.0</lon>
            <nSearchNo />
            <motd />
            <emailContact>email_not_found@noemailfound.noemail</emailContact>
        </region>
    </regions>
</data>
XML

      expect(page.html.gsub(/\s/, '').downcase).to include(page_contents.gsub(/\s/, '').downcase)
      expect(current_url).to match(%r{\/portland\/regions.xml})
    end

    it 'handles location detail' do
      location = FactoryGirl.create(:location, name: 'Sasston', street: '303 Southeast 3rd Avenue', city: 'Portland', state: 'OR', zip: '97214', lat: 12, lon: 21, region: @region)
      machine = FactoryGirl.create(:machine, name: "Cleo's Adventure")
      FactoryGirl.create(:location_machine_xref, location: location, machine: machine)

      visit '/iphone.html?get_location=1'

      page_contents = <<XML
<data>
  <locations>
      <location>
          <id>1</id>
          <name>Sasston</name>
          <zoneNo/>
          <zone/>
          <neighborhood/>
          <lat>12.0</lat>
          <lon>21.0</lon>
          <street1>303 Southeast 3rd Avenue</street1>
          <street2/>
          <city>Portland</city>
          <state>OR</state>
          <zip>97214</zip>
          <phone/>
          <numMachines>1</numMachines>
          <machines>
              <machine>
                  <id>1</id>
                  <name>Cleo's Adventure</name>
              </machine>
          </machines>
      </location>
  </locations>
</data>
XML
      expect(page.html.gsub(/\s/, '').downcase).to include(page_contents.gsub(/\s/, '').downcase)
      expect(current_url).to match(%r{\/portland\/locations\/1.xml})
    end

    it 'handles locations for machine' do
      sasston = FactoryGirl.create(:location, name: 'Sasston', street: '303 Southeast 3rd Avenue', city: 'Portland', state: 'OR', zip: '97214', region: @region)
      cleoville = FactoryGirl.create(:location, name: 'Cleoville', region: @region)
      cleos_adventure = FactoryGirl.create(:machine, id: 1, name: "Cleo's Adventure")

      FactoryGirl.create(:location, name: 'Bawbston', region: @region)

      FactoryGirl.create(:location_machine_xref, location: sasston, machine: cleos_adventure)
      FactoryGirl.create(:location_machine_xref, location: cleoville, machine: cleos_adventure)

      visit '/iphone.html?get_machine=1'

      page_contents = <<XML
<data>
  <locations>
      <location>
          <id>2</id>
          <name>Cleoville</name>
          <zoneNo/>
          <zone/>
          <neighborhood/>
          <lat>11.11</lat>
          <lon>-11.11</lon>
          <street1>303 Southeast 3rd Avenue</street1>
          <street2/>
          <city>Portland</city>
          <state>OR</state>
          <zip>97214</zip>
          <phone/>
          <numMachines>1</numMachines>
      </location>
      <location>
          <id>1</id>
          <name>Sasston</name>
          <zoneNo/>
          <zone/>
          <neighborhood/>
          <lat>11.11</lat>
          <lon>-11.11</lon>
          <street1>303 Southeast 3rd Avenue</street1>
          <street2/>
          <city>Portland</city>
          <state>OR</state>
          <zip>97214</zip>
          <phone/>
          <numMachines>1</numMachines>
      </location>
  </locations>
</data>
XML
      expect(current_url).to match(%r{\/portland\/locations\/1\/locations_for_machine.xml})
      expect(page.html.gsub(/\s/, '').downcase).to include(page_contents.gsub(/\s/, '').downcase)
    end

    it 'updates conditions' do
      sasston = FactoryGirl.create(:location, name: 'Sasston', street: '303 Southeast 3rd Avenue', city: 'Portland', state: 'OR', zip: '97214', lat: 12, lon: 21, region: @region)
      machine = FactoryGirl.create(:machine, name: "Cleo's Adventure")
      FactoryGirl.create(:location_machine_xref, location: sasston, machine: machine, condition: 'foo')

      page.driver.headers = { 'User-Agent' => 'Mozilla/5.0 (cleOS)' }

      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          body: "bar\nCleo's Adventure\nSasston\nportland\n(entered from 127.0.0.1 via Mozilla/5.0 (cleOS))",
          subject: 'PBM - Someone entered a machine condition',
          to: [],
          from: 'admin@pinballmap.com'
        )
      end

      visit '/iphone.html?condition=bar;location_no=1;machine_no=1'

      page_contents = <<XML
<data>
  <msg>add successful</msg>
</data>
XML
      expect(page.html.gsub(/\s/, '').downcase).to include(page_contents.gsub(/\s/, '').downcase)
      expect(current_url).to match(%r{\/portland\/location_machine_xrefs\/1\/condition_update_confirmation.xml})
    end

    it 'lets you add existing machines to a location by machine_no' do
      FactoryGirl.create(:location, region: @region)
      FactoryGirl.create(:machine, name: "Cleo's Adventure")
      FactoryGirl.create(:machine, name: "Bawb's Adventure")

      visit '/iphone.html?modify_location=1;machine_no=2'

      page_contents = <<XML
<data>
  <msg>add successful</msg>
  <id>2</id>
</data>
XML
      expect(page.html.gsub(/\s/, '').downcase).to include(page_contents.gsub(/\s/, '').downcase)
    end

    it 'lets you add existing machines to a location by machine_name' do
      FactoryGirl.create(:location, region: @region)
      FactoryGirl.create(:machine, name: 'Cleo')
      FactoryGirl.create(:machine, name: "Bawb's Adventure")

      visit '/iphone.html?modify_location=1;machine_name=Cleo'

      page_contents = <<XML
<data>
  <msg>add successful</msg>
  <id>1</id>
</data>
XML
      expect(page.html.gsub(/\s/, '').downcase).to include(page_contents.gsub(/\s/, '').downcase)
    end

    it 'lets you add existing machines to a location by machine_name case insensitive' do
      FactoryGirl.create(:location, region: @region)
      FactoryGirl.create(:machine, name: 'Cleo')
      FactoryGirl.create(:machine, name: "Bawb's Adventure")

      visit '/iphone.html?modify_location=1;machine_name=cleo'

      page_contents = <<XML
<data>
  <msg>add successful</msg>
  <id>1</id>
</data>
XML
      expect(page.html.gsub(/\s/, '').downcase).to include(page_contents.gsub(/\s/, '').downcase)

      expect(Machine.all.count).to eq(2)
    end

    it 'lets you add existing machines to a location by machine_name ignores preceeding and trailing whitespace' do
      FactoryGirl.create(:location, region: @region)
      FactoryGirl.create(:machine, name: 'Cleo')
      FactoryGirl.create(:machine, name: "Bawb's Adventure")

      visit '/iphone.html?modify_location=1;machine_name=%20cleo%20'

      page_contents = <<XML
<data>
  <msg>add successful</msg>
  <id>1</id>
</data>
XML
      expect(page.html.gsub(/\s/, '').downcase).to include(page_contents.gsub(/\s/, '').downcase)

      expect(Machine.all.count).to eq(2)
    end

    it 'lets you add machines that are not in the system' do
      sasston = FactoryGirl.create(:location, region: @region)
      FactoryGirl.create(:machine, name: 'Cleo')

      visit '/iphone.html?modify_location=1;machine_name=Satchmo'

      page_contents = <<XML
<data>
  <msg>add successful</msg>
  <id>2</id>
</data>
XML
      expect(page.html.gsub(/\s/, '').downcase).to include(page_contents.gsub(/\s/, '').downcase)
      expect(sasston.machines.first.name).to eq('Satchmo')
    end

    it 'lets you remove a machine' do
      sasston = FactoryGirl.create(:location, name: 'sasston', region: @region)
      machine = FactoryGirl.create(:machine, name: 'Cleo')
      FactoryGirl.create(:location_machine_xref, location: sasston, machine: machine)

      page.driver.headers = { 'User-Agent' => 'Mozilla/5.0 (cleOS)' }

      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          body: "sasston\nCleo\nportland\n(entered from 127.0.0.1 via Mozilla/5.0 (cleOS))",
          subject: 'PBM - Someone removed a machine from a location',
          to: [],
          from: 'admin@pinballmap.com'
        )
      end

      visit '/iphone.html?modify_location=1;machine_no=1'

      page_contents = <<XML
<data>
  <msg>remove successful</msg>
</data>
XML
      expect(page.html.gsub(/\s/, '').downcase).to include(page_contents.gsub(/\s/, '').downcase)
      expect(current_url).to match(%r{\/portland\/location_machine_xrefs\/1\/remove_confirmation.xml})
      expect(sasston.machines.size).to eq(0)
    end

  end
end
