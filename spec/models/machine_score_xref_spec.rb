require 'spec_helper'

describe MachineScoreXref do
  context 'manipulate score data' do
    before(:each) do
      @lmx = FactoryGirl.create(:location_machine_xref, location: FactoryGirl.create(:location), machine: FactoryGirl.create(:machine))
    end

    describe '#username' do
      it 'should display blank when there is no user associated with the score' do
        userless_score = FactoryGirl.create(:machine_score_xref, location_machine_xref: @lmx, user: nil)
        expect(userless_score.username).to eq('')

        user_score = FactoryGirl.create(:machine_score_xref, location_machine_xref: @lmx, user: FactoryGirl.create(:user, username: 'cibw'))
        expect(user_score.username).to eq('cibw')
      end
    end
  end
end
