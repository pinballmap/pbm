require 'spec_helper'

describe Region do
  describe '#n_recent_scores' do
    it 'should return the most recent n scores' do
      r = Factory.create(:region, :name => 'portland')
      lmx = Factory.create(:location_machine_xref, :location => Factory.create(:location, :region => r))
      one = Factory.create(:machine_score_xref, :location_machine_xref => lmx, :created_at => '2001-01-01')
      two = Factory.create(:machine_score_xref, :location_machine_xref => lmx, :created_at => '2001-02-01')
      three = Factory.create(:machine_score_xref, :location_machine_xref => lmx, :created_at => '2001-03-01')
      r.n_recent_scores(2).should == [three, two]
    end
  end

  describe '#n_high_rollers' do
    it 'should return the high n rollers' do
      r = Factory.create(:region, :name => 'portland')
      lmx = Factory.create(:location_machine_xref, :location => Factory.create(:location, :region => r))

      3.times {|n| Factory.create(:user, :initials => "ssw#{n}")}
      scores = Array.new
      3.times {|n| scores << Factory.create(:machine_score_xref, :location_machine_xref => lmx, :user => User.find_by_initials("ssw#{n}"))}
      scores << Factory.create(:machine_score_xref, :location_machine_xref => lmx, :user => User.find_by_initials("ssw0"))

      r.n_high_rollers(2).should == {
        User.find_by_initials("ssw0") => [scores[0], scores[3]],
        User.find_by_initials("ssw1") => [scores[1]],
      }
    end
  end
end
