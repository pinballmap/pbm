require 'spec_helper'

describe Machine do
  before(:each) do
    @machine_group = FactoryBot.create(:machine_group)
    @l = FactoryBot.create(:location)
    @m = FactoryBot.create(:machine, name: 'Sassy', machine_group: @machine_group)
    @lmx = FactoryBot.create(:location_machine_xref, location: @l, machine: @m)
    @msx = FactoryBot.create(:machine_score_xref, location_machine_xref: @lmx)
  end

  describe '#before_destroy' do
    it 'should clean up location_machine_xrefs, events, location_picture_xrefs' do
      @m.destroy

      expect(Machine.all).to eq([])
      expect(LocationMachineXref.all).to eq([])
      expect(MachineScoreXref.all).to eq([])
    end
  end

  describe '#all_machines_in_machine_group' do
    it 'should return this machine and all machines group together with it' do
      sassy_champ = FactoryBot.create(:machine, name: 'Sassy Championship Edition', machine_group: @machine_group)

      expect(@m.all_machines_in_machine_group).to include(@m, sassy_champ)
    end
  end

  describe '#tag_with_opdb_json' do
    it 'add or update opdb data to machines using opdb json export' do
      m1 = FactoryBot.create(:machine, ipdb_id: 123)
      m2 = FactoryBot.create(:machine, ipdb_id: 456)
      m3 = FactoryBot.create(:machine, ipdb_id: nil)

      Machine.tag_with_opdb_json(<<HERE)
[{"opdb_id":"G50L9-MDxXD","is_machine":true,"name":"Challenger","shortname":"","ipdb_id":123,"manufacture_date":"1971-03-01","manufacturer":{"manufacturer_id":2,"name":"Gottlieb","full_name":"D. Gottlieb & Co.","created_at":"2018-03-11","updated_at":"2018-03-11"},"type":"em","display":"reels","player_count":2,"features":["Head-to-head play"],"keywords":[],"description":"","created_at":"2018-03-11","updated_at":"2018-05-08"},{"opdb_id":"GR7V3-MQPyL","is_machine":true,"name":"Moon Shot","shortname":"","ipdb_id":1628,"manufacture_date":"1969-08-01","manufacturer":{"manufacturer_id":3,"name":"Chicago Coin","full_name":"Chicago Coin Machine Mfg. Co.","created_at":"2018-03-11","updated_at":"2018-03-11"},"type":"em","display":"reels","player_count":4,"features":[],"keywords":[],"description":null,"created_at":"2018-03-11","updated_at":"2018-05-08"},{"opdb_id":"GRDlQ-MJ9yJ","is_machine":true,"name":"Galaxy Play","shortname":"","ipdb_id":456,"manufacture_date":"1986-01-01","manufacturer":{"manufacturer_id":4,"name":"Cic Play","full_name":"Consolidated Industries Co.","created_at":"2018-03-11","updated_at":"2018-03-11" },"type":"ss","display":"alphanumeric","player_count":4,"features":[],"keywords":[],"description":"","created_at":"2018-03-11","updated_at":"2018-04-05"}]
HERE

      expect(m1.reload.opdb_id).to eq('G50L9-MDxXD')
      expect(m2.reload.opdb_id).to eq('GRDlQ-MJ9yJ')
      expect(m3.reload.opdb_id).to eq(nil)
    end
  end
end
