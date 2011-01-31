require 'spec_helper'

describe MachineScoreXref do
  describe 'scopes' do
    before(:each) do
      @lmx = Factory.create(:location_machine_xref, :location => Factory.create(:location), :machine => Factory.create(:machine))
      @gc = Factory.create(:machine_score_xref, :location_machine_xref => @lmx, :rank => 1, :score => 1000, :initials => 'ssw')
      @first = Factory.create(:machine_score_xref, :location_machine_xref => @lmx, :rank => 2, :score => 500,  :initials => 'ccw')
      @second = Factory.create(:machine_score_xref, :location_machine_xref => @lmx, :rank => 3, :score => 250,  :initials => 'sbw')
    end

    describe '#sanitize_scores' do
      it 'should remove scores that are no longer possible' do
        new_gc = Factory.create(:machine_score_xref, :location_machine_xref => @lmx, :rank => 1, :score => 400, :initials => 'rcb')
        new_gc.sanitize_scores

        scores = MachineScoreXref.find(:all).sort {|a,b| a.rank <=> b.rank}
        scores.should == [ new_gc, @second ]
      end

      it 'should remove scores that are no longer possible' do
        new_first = Factory.create(:machine_score_xref, :location_machine_xref => @lmx, :rank => 2, :score => 1100, :initials => 'rcb')
        new_first.sanitize_scores

        scores = MachineScoreXref.find(:all).sort {|a,b| a.rank <=> b.rank}
        scores.should == [ new_first, @second ]
      end
    end
  end
end
