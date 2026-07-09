require 'spec_helper'

describe 'update_lmx_counts rake task' do
  before(:all) do
    Rails.application.load_tasks
  end

  def run_task
    Rake::Task['update_lmx_counts'].reenable
    Rake::Task['update_lmx_counts'].invoke
  end

  it 'sets lmx_count to the number of location_machine_xrefs for that machine' do
    machine = FactoryBot.create(:machine)
    FactoryBot.create(:location_machine_xref, machine: machine)
    FactoryBot.create(:location_machine_xref, machine: machine)

    run_task

    expect(machine.reload.lmx_count).to eq(2)
  end

  it 'excludes soft-deleted location_machine_xrefs from the count' do
    machine = FactoryBot.create(:machine)
    FactoryBot.create(:location_machine_xref, machine: machine)
    deleted_lmx = FactoryBot.create(:location_machine_xref, machine: machine)
    deleted_lmx.update_columns(deleted_at: Time.current)

    run_task

    expect(machine.reload.lmx_count).to eq(1)
  end

  it 'resets lmx_count to 0 for machines with no location_machine_xrefs' do
    machine = FactoryBot.create(:machine)
    machine.update_columns(lmx_count: 5)

    run_task

    expect(machine.reload.lmx_count).to eq(0)
  end

  it 'clears the lmx_count mobile cache key' do
    expect(Rails.cache).to receive(:delete).with(Machine::MOBILE_CACHE_KEY_WITH_LMX_COUNT).at_least(:once)

    run_task
  end

  it 'updates the machines status timestamp so clients know to refetch' do
    status = FactoryBot.create(:status, status_type: 'machines', updated_at: 1.day.ago)

    run_task

    expect(status.reload.updated_at).to be_within(1.second).of Time.current
  end
end
