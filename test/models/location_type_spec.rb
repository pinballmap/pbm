require 'spec_helper'

describe LocationType do
  before(:each) do
    @status = FactoryBot.create(:status, status_type: 'location_types', updated_at: Time.current - 1.day)
    @lt = FactoryBot.create(:location_type, name: 'Broom Closet')
  end

  describe '#before_destroy' do
    it 'should update timestamp in status table' do
      @lt.destroy

      assert_in_delta Time.current, @status.reload.updated_at, 1.second
    end
  end

  describe '#create' do
    it 'should update timestamp in status table' do
      FactoryBot.create(:location_type, name: 'Waterpark')

      assert_in_delta Time.current, @status.reload.updated_at, 1.second
    end
  end

  describe '#update' do
    it 'should update timestamp in status table' do
      @lt.update(library: 'broom')

      assert_in_delta Time.current, @status.reload.updated_at, 1.second
    end
  end
end
