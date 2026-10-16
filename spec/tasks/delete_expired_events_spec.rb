require 'spec_helper'

describe 'delete_expired_events rake task' do
  before(:all) do
    # Loading twice, after another task spec, would define the task twice and run it twice
    Rails.application.load_tasks unless Rake::Task.task_defined?('delete_expired_events')
  end

  def run_task
    Rake::Task['delete_expired_events'].reenable
    Rake::Task['delete_expired_events'].invoke
  end

  it 'deletes events more than a week past their end date, or start date when there is no end date, in any region or none' do
    region = FactoryBot.create(:region)
    FactoryBot.create(:event, region: region, name: 'Ended', start_date: Date.current - 20, end_date: Date.current - 8)
    FactoryBot.create(:event, region: nil, name: 'Ended no region', start_date: Date.current - 8, end_date: Date.current - 8)
    FactoryBot.create(:event, region: region, name: 'Started', start_date: Date.current - 8)
    FactoryBot.create(:event, region: region, name: 'Ended a week ago', start_date: Date.current - 7, end_date: Date.current - 7)
    FactoryBot.create(:event, region: region, name: 'Long event still running', start_date: Date.current - 20, end_date: Date.current + 1)
    FactoryBot.create(:event, region: nil, name: 'Upcoming no region', start_date: Date.current + 3, end_date: Date.current + 3)
    FactoryBot.create(:event, region: region, name: 'End only', start_date: nil, end_date: Date.current)
    FactoryBot.create(:event, region: region, name: 'No dates')

    expect { run_task }.to output("Deleted 3 expired events\n").to_stdout

    expect(Event.pluck(:name)).to match_array([ 'Ended a week ago', 'Long event still running', 'Upcoming no region', 'End only', 'No dates' ])
  end
end
