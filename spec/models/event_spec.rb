require 'spec_helper'

describe Event do
  before(:each) do
  end

  describe '#active?' do
    it 'should be active if there is no start or end date' do
      e = FactoryGirl.create(:event, start_date: nil, end_date: nil)
      expect(e.active?).to be(1)
    end

    it 'handles start date with no end date' do
      e = FactoryGirl.create(:event, start_date: Date.today, end_date: nil)
      expect(e.active?).to be(true)

      e = FactoryGirl.create(:event, start_date: Date.today - 2.week, end_date: nil)
      expect(e.active?).to be(false)
    end

    it 'handles end date is present' do
      e = FactoryGirl.create(:event, start_date: nil, end_date: Date.today)
      expect(e.active?).to be(true)

      e = FactoryGirl.create(:event, start_date: nil, end_date: Date.today - 2.week)
      expect(e.active?).to be(false)
    end
  end
end
