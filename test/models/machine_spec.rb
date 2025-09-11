require 'spec_helper'

describe Machine do
  before(:each) do
    @machine_group = FactoryBot.create(:machine_group)
    @l = FactoryBot.create(:location)
    @m = FactoryBot.create(:machine, name: 'Sassy', machine_group: @machine_group)
    @lmx = FactoryBot.create(:location_machine_xref, location: @l, machine: @m)
    @msx = FactoryBot.create(:machine_score_xref, location_machine_xref: @lmx)
    @status = FactoryBot.create(:status, status_type: 'machines', updated_at: Time.current - 1.day)
  end

  describe '#before_destroy' do
    it 'should clean up location_machine_xrefs, events, location_picture_xrefs' do
      @m.destroy

      assert_equal [], Machine.all
      assert_equal [], LocationMachineXref.all
      assert_equal [], MachineScoreXref.all
    end

    it 'should update timestamp in status table' do
      @m.destroy

      assert_in_delta Time.current, @status.reload.updated_at, 1.second
    end
  end

  describe '#create' do
    it 'should update timestamp in status table' do
      FactoryBot.create(:machine, name: 'Solomon', machine_group: @machine_group)

      assert_in_delta Time.current, @status.reload.updated_at, 1.second
    end
  end

  describe '#update' do
    it 'should update timestamp in status table' do
      @m.update(manufacturer: 'Stern')

      assert_in_delta Time.current, @status.reload.updated_at, 1.second
    end
  end

  describe '#all_machines_in_machine_group' do
    it 'should return this machine and all machines group together with it' do
      sassy_champ = FactoryBot.create(:machine, name: 'Sassy Championship Edition', machine_group: @machine_group)

      assert_includes @m.all_machines_in_machine_group, @m, sassy_champ
    end
  end

  describe '#tag_with_opdb_image_json' do
    it 'add or update opdb data to machines using opdb json export' do
      m1 = FactoryBot.create(:machine, opdb_id: 'G50L9-MDxXD', opdb_img: nil)
      m2 = FactoryBot.create(:machine, opdb_id: 'GR7V3-MQPyL', opdb_img: nil)
      m3 = FactoryBot.create(:machine, opdb_id: 'GRDlQ-MJ9yJ', opdb_img: nil)

      Machine.tag_with_opdb_image_json(<<HERE)
{"machineGroups":[],"machines":[{"opdbId":"G50L9-MDxXD","isMachine":true,"name":"Challenger","commonName":null,"shortname":"","physicalMachine":1,"ipdbId":483,"manufactureDate":"1971-03-01","manufacturer":{"manufacturerId":2,"name":"Gottlieb","fullName":"D. Gottlieb & Co.","createdAt":"2018-03-11","updatedAt":"2018-03-11"},"type":"em","display":"reels","playerCount":2,"features":["Head-to-head play"],"keywords":[],"description":"","images":[{"group":"46a61cc7-8a85-4483-bc7c-d42251419868","title":"Backglass","primary":true,"type":"backglass","urls":{"medium":"https:\/\/img.opdb.org\/46a61cc7-8a85-4483-bc7c-d42251419868-medium.jpg","large":"https:\/\/img.opdb.org\/46a61cc7-8a85-4483-bc7c-d42251419868-large.jpg","small":"https:\/\/img.opdb.org\/46a61cc7-8a85-4483-bc7c-d42251419868-small.jpg"},"sizes":{"medium":{"width":640,"height":445},"large":{"width":640,"height":445},"small":{"width":250,"height":174}}}],"createdAt":"2018-03-11","updatedAt":"2018-05-08"},{"opdbId":"GR7V3-MQPyL","isMachine":true,"name":"Moon Shot","commonName":null,"shortname":"","physicalMachine":1,"ipdbId":1628,"manufactureDate":"1969-08-01","manufacturer":{"manufacturerId":3,"name":"Chicago Coin","fullName":"Chicago Coin Machine Mfg. Co.","createdAt":"2018-03-11","updatedAt":"2018-03-11"},"type":"em","display":"reels","playerCount":4,"features":[],"keywords":[],"description":null,"images":[{"group":"1f4c8baa-3263-45cc-9cdf-8bca641f5270","title":"Backglass","primary":true,"type":"backglass","urls":{"medium":"https:\/\/img.opdb.org\/1f4c8baa-3263-45cc-9cdf-8bca641f5270-medium.jpg","large":"https:\/\/img.opdb.org\/1f4c8baa-3263-45cc-9cdf-8bca641f5270-large.jpg","small":"https:\/\/img.opdb.org\/1f4c8baa-3263-45cc-9cdf-8bca641f5270-small.jpg"},"sizes":{"medium":{"width":640,"height":603},"large":{"width":765,"height":721},"small":{"width":250,"height":236}}}],"createdAt":"2018-03-11","updatedAt":"2018-05-08"},{"opdbId":"GRDlQ-MJ9yJ","isMachine":true,"name":"Galaxy Play","commonName":null,"shortname":"","physicalMachine":1,"ipdbId":4631,"manufactureDate":"1986-01-01","manufacturer":{"manufacturerId":4,"name":"Cic Play","fullName":"Consolidated Industries Co.","createdAt":"2018-03-11","updatedAt":"2018-03-11"},"type":"ss","display":"alphanumeric","playerCount":4,"features":[],"keywords":[],"description":"","images":[{"group":"eb583dfc-cfc5-42fa-9459-eefa0357bf56","title":"Backglass","primary":false,"type":"backglass","urls":{"medium":"https:\/\/img.opdb.org\/eb583dfc-cfc5-42fa-9459-eefa0357bf56-medium.jpg","large":"https:\/\/img.opdb.org\/eb583dfc-cfc5-42fa-9459-eefa0357bf56-large.jpg","small":"https:\/\/img.opdb.org\/eb583dfc-cfc5-42fa-9459-eefa0357bf56-small.jpg"},"sizes":{"medium":{"width":640,"height":572},"large":{"width":671,"height":600},"small":{"width":250,"height":224}}}],"createdAt":"2018-03-11","updatedAt":"2018-04-05"}],"aliases":[]}
HERE

      assert_equal 'https://img.opdb.org/46a61cc7-8a85-4483-bc7c-d42251419868-medium.jpg', m1.reload.opdb_img
      assert_equal 'https://img.opdb.org/1f4c8baa-3263-45cc-9cdf-8bca641f5270-medium.jpg', m2.reload.opdb_img
      assert_equal nil, m3.reload.opdb_img
    end
  end
end
