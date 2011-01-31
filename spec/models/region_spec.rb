require 'spec_helper'

describe Region do
  describe '#n_recent_scores' do
    it 'should return the most recent n scores' do
      r = Factory.create(:region, :name => 'portland')
      lmx = Factory.create(:location_machine_xref, :location => Factory.create(:location, :region => r))
      scores = 3.times { Factory.create(:machine_score_xref, :location_machine_xref => lmx) }
      r.n_recent_scores(2) == [scores[2], scores[1]]
    end
  end
end
