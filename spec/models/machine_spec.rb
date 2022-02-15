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
      m1 = FactoryBot.create(:machine, opdb_id: 'G50L9-MDxXD', opdb_img: nil)
      m2 = FactoryBot.create(:machine, opdb_id: 'GR7V3-MQPyL', opdb_img: nil)
      m3 = FactoryBot.create(:machine, opdb_id: 'GRDlQ-MJ9yJ', opdb_img: nil)

      Machine.tag_with_opdb_json(<<HERE)
[{"opdb_id":"G50L9-MDxXD","is_machine":true,"name":"Challenger","common_name":null,"shortname":"","physical_machine":1,"ipdb_id":483,"manufacture_date":"1971-03-01","manufacturer":{"manufacturer_id":2,"name":"Gottlieb","full_name":"D. Gottlieb & Co.","created_at":"2018-03-11","updated_at":"2018-03-11"},"type":"em","display":"reels","player_count":2,"features":["Head-to-head play"],"keywords":[],"description":"","created_at":"2018-03-11","updated_at":"2018-05-08","images":[{"title":"Backglass","primary":true,"type":"backglass","urls":{"medium":"https:\/\/img.opdb.org\/46a61cc7-8a85-4483-bc7c-d42251419868-medium.jpg","large":"https:\/\/img.opdb.org\/46a61cc7-8a85-4483-bc7c-d42251419868-large.jpg","small":"https:\/\/img.opdb.org\/46a61cc7-8a85-4483-bc7c-d42251419868-small.jpg"},"sizes":{"medium":{"width":640,"height":445},"large":{"width":640,"height":445},"small":{"width":250,"height":174}}}]},{"opdb_id":"GR7V3-MQPyL","is_machine":true,"name":"Moon Shot","common_name":null,"shortname":"","physical_machine":1,"ipdb_id":1628,"manufacture_date":"1969-08-01","manufacturer":{"manufacturer_id":3,"name":"Chicago Coin","full_name":"Chicago Coin Machine Mfg. Co.","created_at":"2018-03-11","updated_at":"2018-03-11"},"type":"em","display":"reels","player_count":4,"features":[],"keywords":[],"description":null,"created_at":"2018-03-11","updated_at":"2018-05-08","images":[{"title":"Backglass","primary":true,"type":"backglass","urls":{"medium":"https:\/\/img.opdb.org\/1f4c8baa-3263-45cc-9cdf-8bca641f5270-medium.jpg","large":"https:\/\/img.opdb.org\/1f4c8baa-3263-45cc-9cdf-8bca641f5270-large.jpg","small":"https:\/\/img.opdb.org\/1f4c8baa-3263-45cc-9cdf-8bca641f5270-small.jpg"},"sizes":{"medium":{"width":640,"height":603},"large":{"width":765,"height":721},"small":{"width":250,"height":236}}}]},{"opdb_id":"GRDlQ-MJ9yJ","is_machine":true,"name":"Galaxy Play","common_name":null,"shortname":"","physical_machine":1,"ipdb_id":4631,"manufacture_date":"1986-01-01","manufacturer":{"manufacturer_id":4,"name":"Cic Play","full_name":"Consolidated Industries Co.","created_at":"2018-03-11","updated_at":"2018-03-11"},"type":"ss","display":"alphanumeric","player_count":4,"features":[],"keywords":[],"description":"","created_at":"2018-03-11","updated_at":"2018-04-05","images":[{"title":"Backglass","primary":false,"type":"backglass","urls":{"medium":"https:\/\/img.opdb.org\/eb583dfc-cfc5-42fa-9459-eefa0357bf56-medium.jpg","large":"https:\/\/img.opdb.org\/eb583dfc-cfc5-42fa-9459-eefa0357bf56-large.jpg","small":"https:\/\/img.opdb.org\/eb583dfc-cfc5-42fa-9459-eefa0357bf56-small.jpg"},"sizes":{"medium":{"width":640,"height":572},"large":{"width":671,"height":600},"small":{"width":250,"height":224}}}]}]
HERE

      expect(m1.reload.opdb_img).to eq('https://img.opdb.org/46a61cc7-8a85-4483-bc7c-d42251419868-medium.jpg')
      expect(m2.reload.opdb_img).to eq('https://img.opdb.org/1f4c8baa-3263-45cc-9cdf-8bca641f5270-medium.jpg')
      expect(m3.reload.opdb_img).to eq(nil)
    end
  end
end
