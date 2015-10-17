require 'spec_helper'

describe Operator do
  before(:each) do
    @r = FactoryGirl.create(:region, full_name: 'Portland')
    @o = FactoryGirl.create(:operator, region: @r)
  end

  describe '#recent_comments_email_body' do
    it 'Sends emails to operators with recent comments on their machines' do
      l = FactoryGirl.create(:location, region: @r, operator: @o, name: 'Cleo Corner')

      m1 = FactoryGirl.create(:machine, name: 'Sassy')
      m2 = FactoryGirl.create(:machine, name: 'Cleo')
      lmx1 = FactoryGirl.create(:location_machine_xref, location: l, machine: m1)
      lmx2 = FactoryGirl.create(:location_machine_xref, location: l, machine: m2)

      FactoryGirl.create(:machine_condition, location_machine_xref: lmx1, comment: 'Sassy Comment')
      FactoryGirl.create(:machine_condition, location_machine_xref: lmx2, comment: 'Cleo Comment')
      FactoryGirl.create(:machine_condition, location_machine_xref: lmx2, comment: 'Old Cleo Comment', created_at: Date.today - 2.days)

      expect(@o.recent_comments_email_body).to eq(<<HERE)
Here's a list of comments made on your pinball machines that were posted today to #{@o.region.full_name}. We're sending this in the hope that it will help you identify, and fix, problems. If you don't want to receive these messages, please contact pinballmap@posteo.org.

Comment: Cleo Comment
Location: Cleo Corner - 303 Southeast 3rd Avenue, Portland, OR, 97214
Machine: Cleo

Comment: Sassy Comment
Location: Cleo Corner - 303 Southeast 3rd Avenue, Portland, OR, 97214
Machine: Sassy
HERE
    end
  end
end
