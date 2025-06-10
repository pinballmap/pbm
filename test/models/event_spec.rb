require 'spec_helper'

describe Event do
  before(:each) do
  end

  describe '#active?' do
    it 'should be active if there is no start or end date' do
      e = FactoryBot.create(:event, start_date: nil, end_date: nil)
      assert_same 1, e.active?
    end

    it 'handles start date with no end date' do
      e = FactoryBot.create(:event, start_date: Date.today, end_date: nil)
      assert e.active?

      e = FactoryBot.create(:event, start_date: Date.today - 2.week, end_date: nil)
      refute e.active?
    end

    it 'handles end date is present' do
      e = FactoryBot.create(:event, start_date: nil, end_date: Date.today)
      assert e.active?

      e = FactoryBot.create(:event, start_date: nil, end_date: Date.today - 2.week)
      refute e.active?
    end
  end
end
