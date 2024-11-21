require 'spec_helper'

describe LocationType do
  before(:each) do
    @status = FactoryBot.create(:status, status_type: 'location_types', updated_at: Time.current - 1.day)
    @lt = FactoryBot.create(:location_type, name: 'Broom Closet')
  end

  describe '#before_destroy' do
    it 'should update timestamp in status table' do
      @lt.destroy

      expect(@status.reload.updated_at).to be_within(1.second).of Time.current
    end
  end

  describe '#create' do
    it 'should update timestamp in status table' do
      FactoryBot.create(:location_type, name: 'Waterpark')

      expect(@status.reload.updated_at).to be_within(1.second).of Time.current
    end
  end

  describe '#update' do
    it 'should update timestamp in status table' do
      @lt.update(library: 'broom')

      expect(@status.reload.updated_at).to be_within(1.second).of Time.current
    end
  end
end
