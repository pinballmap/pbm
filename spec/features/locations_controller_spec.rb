require 'spec_helper'

describe LocationsController do
  before(:each) do
    @region = FactoryGirl.create(:region, :name => 'portland', :full_name => 'portland', :lat => 1, :lon => 2, :motd => 'This is a MOTD', :n_search_no => 4, :should_email_machine_removal => 1)
  end

  describe 'mobile', :type => :feature, :js => true do

    it 'defaults to portland if no region is given' do
      visit '/iphone.html?init=1'

      expect(current_url).to match(/\/portland\/locations.xml/)
    end

    it 'honors region param' do
      FactoryGirl.create(:region, :name => 'toronto')

      visit '/iphone.html?init=1;region=toronto'

      expect(current_url).to match(/\/toronto\/locations.xml/)
    end

    it 'takes an optional format parameter' do
      FactoryGirl.create(:region, :name => 'toronto')

      visit '/iphone.html?init=1;region=toronto;format=json'

      expect(current_url).to match(/\/toronto\/locations.json/)
    end

    it 'respects all region data init param' do
      FactoryGirl.create(:region, :name => 'toronto')

      visit '/iphone.html?init=5;region=toronto'

      expect(current_url).to match(/\/toronto\/all_region_data.json/)
    end

    it 'handles init=1' do
      location = FactoryGirl.create(:location, :region => @region, :name => 'Sasston', :lat => 12, :lon => 21)
      zone = FactoryGirl.create(:zone, :region => @region, :name => 'NE')
      machine = FactoryGirl.create(:machine, :name => 'Batman')
      FactoryGirl.create(:location_machine_xref, :location => location, :machine => machine)

      visit '/iphone.html?init=1'

      expect(current_url).to match(/\/portland\/locations.xml/)

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
      expect(page.html.gsub(/\s/,'').downcase).to include(page_contents.gsub(/\s/,'').downcase)
    end

    it 'works for 4sq' do
      toronto = FactoryGirl.create(:region, :name => 'toronto', :full_name => 'toronto', :lat => 3, :lon => 4)
      bawb_location = FactoryGirl.create(:location, :name => 'Bawb', :lat => 1, :lon => 1, :street => '123 pine', :city => 'portland', :state => 'OR', :zip => 97211, :phone => '555-555-5555', :region => @region)
      cleo_location = FactoryGirl.create(:location, :name => 'Cleo', :lat => 2, :lon => 2, :street => '456 oak', :city => 'toronto', :state => 'IL', :zip => 55555, :phone => '123-456-7890', :region => toronto)
      spiderman = FactoryGirl.create(:machine, :name => 'Spider-Man')
      batman = FactoryGirl.create(:machine, :name => 'Batman')
      FactoryGirl.create(:location_machine_xref, :location => bawb_location, :machine => spiderman)
      FactoryGirl.create(:location_machine_xref, :location => bawb_location, :machine => batman)
      FactoryGirl.create(:location_machine_xref, :location => cleo_location, :machine => spiderman)

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
      expect(page.html.gsub(/\s/,'').downcase).to include(page_contents.gsub(/\s/,'').downcase)
    end

    it 'region initialization' do
      toronto = FactoryGirl.create(:region, :name => 'bayarea', :full_name => 'Bay Area', :lat => 3, :lon => 4)
      FactoryGirl.create(:user, :email => 'foo@bar.com', :region => @region)

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

      expect(page.html.gsub(/\s/,'').downcase).to include(page_contents.gsub(/\s/,'').downcase)
      expect(current_url).to match(/\/portland\/regions.xml/)
    end

    it 'handles location detail' do
      location = FactoryGirl.create(:location, :name => 'Sasston', :street => '303 Southeast 3rd Avenue', :city => 'Portland', :state => 'OR', :zip => 97214, :lat => 12, :lon => 21, :region => @region)
      machine = FactoryGirl.create(:machine, :name => "Cleo's Adventure")
      FactoryGirl.create(:location_machine_xref, :location => location, :machine => machine)

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
      expect(page.html.gsub(/\s/,'').downcase).to include(page_contents.gsub(/\s/,'').downcase)
      expect(current_url).to match(/\/portland\/locations\/1.xml/)
    end

    it 'handles locations for machine' do
      sasston = FactoryGirl.create(:location, :name => 'Sasston', :street => '303 Southeast 3rd Avenue', :city => 'Portland', :state => 'OR', :zip => 97214, :region => @region)
      cleoville = FactoryGirl.create(:location, :name => 'Cleoville', :region => @region)
      cleos_adventure = FactoryGirl.create(:machine, :id => 1, :name => "Cleo's Adventure")

      FactoryGirl.create(:location, :name => 'Bawbston', :region => @region)

      FactoryGirl.create(:location_machine_xref, :location => sasston, :machine => cleos_adventure)
      FactoryGirl.create(:location_machine_xref, :location => cleoville, :machine => cleos_adventure)

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
      expect(current_url).to match(/\/portland\/locations\/1\/locations_for_machine.xml/)
      expect(page.html.gsub(/\s/,'').downcase).to include(page_contents.gsub(/\s/,'').downcase)
    end

    it 'updates conditions' do
      sasston = FactoryGirl.create(:location, :name => 'Sasston', :street => '303 Southeast 3rd Avenue', :city => 'Portland', :state => 'OR', :zip => 97214, :lat => 12, :lon => 21, :region => @region)
      machine = FactoryGirl.create(:machine, :name => "Cleo's Adventure")
      FactoryGirl.create(:location_machine_xref, :location => sasston, :machine => machine, :condition => 'foo')

      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          :body => "bar\nCleo's Adventure\nSasston\nportland\n(entered from 127.0.0.1)",
          :subject => "PBM - Someone entered a machine condition",
          :to => [],
          :from =>"admin@pinballmap.com"
        )
      end

      visit '/iphone.html?condition=bar;location_no=1;machine_no=1'

      page_contents = <<XML
<data>
  <msg>add successful</msg>
</data>
XML
      expect(page.html.gsub(/\s/,'').downcase).to include(page_contents.gsub(/\s/,'').downcase)
      expect(current_url).to match(/\/portland\/location_machine_xrefs\/1\/condition_update_confirmation.xml/)
    end

    it 'lets you add existing machines to a location by machine_no' do
      sasston = FactoryGirl.create(:location, :region => @region)
      FactoryGirl.create(:machine, :name => "Cleo's Adventure")
      FactoryGirl.create(:machine, :name => "Bawb's Adventure")

      visit '/iphone.html?modify_location=1;machine_no=2'

      page_contents = <<XML
<data>
  <msg>add successful</msg>
  <id>2</id>
</data>
XML
      expect(page.html.gsub(/\s/,'').downcase).to include(page_contents.gsub(/\s/,'').downcase)
    end

    it 'lets you add existing machines to a location by machine_name' do
      sasston = FactoryGirl.create(:location, :region => @region)
      FactoryGirl.create(:machine, :name => "Cleo")
      FactoryGirl.create(:machine, :name => "Bawb's Adventure")

      visit '/iphone.html?modify_location=1;machine_name=Cleo'

      page_contents = <<XML
<data>
  <msg>add successful</msg>
  <id>1</id>
</data>
XML
      expect(page.html.gsub(/\s/,'').downcase).to include(page_contents.gsub(/\s/,'').downcase)
    end

    it 'lets you add existing machines to a location by machine_name case insensitive' do
      sasston = FactoryGirl.create(:location, :region => @region)
      FactoryGirl.create(:machine, :name => "Cleo")
      FactoryGirl.create(:machine, :name => "Bawb's Adventure")

      visit '/iphone.html?modify_location=1;machine_name=cleo'

      page_contents = <<XML
<data>
  <msg>add successful</msg>
  <id>1</id>
</data>
XML
      expect(page.html.gsub(/\s/,'').downcase).to include(page_contents.gsub(/\s/,'').downcase)

      expect(Machine.all.count).to eq(2)
    end

    it 'lets you add existing machines to a location by machine_name ignores preceeding and trailing whitespace' do
      sasston = FactoryGirl.create(:location, :region => @region)
      FactoryGirl.create(:machine, :name => "Cleo")
      FactoryGirl.create(:machine, :name => "Bawb's Adventure")

      visit '/iphone.html?modify_location=1;machine_name=%20cleo%20'

      page_contents = <<XML
<data>
  <msg>add successful</msg>
  <id>1</id>
</data>
XML
      expect(page.html.gsub(/\s/,'').downcase).to include(page_contents.gsub(/\s/,'').downcase)

      expect(Machine.all.count).to eq(2)
    end

    it 'lets you add machines that are not in the system' do
      sasston = FactoryGirl.create(:location, :region => @region)
      FactoryGirl.create(:machine, :name => "Cleo")

      visit '/iphone.html?modify_location=1;machine_name=Satchmo'

      page_contents = <<XML
<data>
  <msg>add successful</msg>
  <id>2</id>
</data>
XML
      expect(page.html.gsub(/\s/,'').downcase).to include(page_contents.gsub(/\s/,'').downcase)
      expect(sasston.machines.first.name).to eq('Satchmo')
    end

    it 'lets you remove a machine' do
      sasston = FactoryGirl.create(:location, :name => 'sasston', :region => @region)
      machine = FactoryGirl.create(:machine, :name => "Cleo")
      FactoryGirl.create(:location_machine_xref, :location => sasston, :machine => machine)

      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          :body => "sasston\nCleo\nportland\n(entered from 127.0.0.1)",
          :subject => "PBM - Someone removed a machine from a location",
          :to => [],
          :from =>"admin@pinballmap.com"
        )
      end

      visit '/iphone.html?modify_location=1;machine_no=1'

      page_contents = <<XML
<data>
  <msg>remove successful</msg>
</data>
XML
      expect(page.html.gsub(/\s/,'').downcase).to include(page_contents.gsub(/\s/,'').downcase)
      expect(current_url).to match(/\/portland\/location_machine_xrefs\/1\/remove_confirmation.xml/)
      expect(sasston.machines.size).to eq(0)
    end

  end
end
