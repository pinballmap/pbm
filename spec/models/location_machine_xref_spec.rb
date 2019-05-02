require 'spec_helper'

describe LocationMachineXref do
  before(:each) do
    @r = FactoryBot.create(:region, name: 'Portland', should_email_machine_removal: 1)
    @r_no_email = FactoryBot.create(:region, should_email_machine_removal: 0)

    @u = FactoryBot.create(:user, id: 1, region: @r, username: 'ssw', email: 'foo@bar.com')

    @l = FactoryBot.create(:location, region: @r, name: 'Cool Bar')
    @l_no_email = FactoryBot.create(:location, region: @r_no_email)

    @m = FactoryBot.create(:machine, name: 'Sassy')

    @lmx = FactoryBot.create(:location_machine_xref, location: @l, machine: @m)
    @lmx_no_email = FactoryBot.create(:location_machine_xref, location: @l_no_email, machine: @m)
  end

  describe '#update_condition' do
    it 'should work with regionless locations' do
      regionless_location = FactoryBot.create(:location, region: nil, name: 'REGIONLESS')
      regionless_lmx = FactoryBot.create(:location_machine_xref, location: regionless_location, machine: @m)

      expect(Pony).to_not receive(:mail)

      regionless_lmx.update_condition('regionless condish', user_id: @u.id)

      expect(regionless_lmx.condition).to eq('regionless condish')
      expect(regionless_lmx.condition_date.to_s).to eq(Time.now.to_s.split(' ')[0])

      expect(MachineCondition.all.count).to eq(1)
      expect(MachineCondition.first.comment).to eq('regionless condish')
    end

    it 'should update the condition of the lmx, timestamp it, and email the admins of the region' do
      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          body: "foo\nSassy\nCool Bar\nPortland\n(entered from  via  by ssw (foo@bar.com))",
          subject: 'PBM - Someone entered a machine condition',
          to: ['foo@bar.com'],
          from: 'admin@pinballmap.com'
        )
      end

      @lmx.update_condition('foo', user_id: @u.id)

      expect(@lmx.condition).to eq('foo')
      expect(@lmx.condition_date.to_s).to eq(Time.now.to_s.split(' ')[0])

      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          body: "bar\nSassy\nCool Bar\nPortland\n(entered from 0.0.0.0 via cleOS by ssw (foo@bar.com))",
          subject: 'PBM - Someone entered a machine condition',
          to: ['foo@bar.com'],
          from: 'admin@pinballmap.com'
        )
      end

      @lmx.update_condition('bar', remote_ip: '0.0.0.0', user_agent: 'cleOS', user_id: @u.id)
    end

    it 'should not send an email if the region is set for digest comments' do
      r_digest_email = FactoryBot.create(:region, send_digest_removal_emails: 1, send_digest_comment_emails: 1)
      u_digest_email = FactoryBot.create(:user, id: 2, region: r_digest_email, username: 'cibw', email: 'foo@baz.com')
      l_digest_email = FactoryBot.create(:location, region: r_digest_email)
      lmx_digest_email = FactoryBot.create(:location_machine_xref, location: l_digest_email, machine: @m)

      expect(Pony).to_not receive(:mail)

      lmx_digest_email.update_condition('foo', user_id: u_digest_email.id)

      expect(lmx_digest_email.condition).to eq('foo')
      expect(lmx_digest_email.condition_date.to_s).to eq(Time.now.to_s.split(' ')[0])
    end

    it 'should not send an email for blank condition updates' do
      expect(Pony).to_not receive(:mail)

      @lmx.update_condition('')
    end

    it 'should do nothing if your condition is the same as the previous condition' do
      expect(Pony).to_not receive(:mail)

      @lmx.condition = 'baz'

      @lmx.update_condition('baz')

      expect(MachineCondition.all.count).to eq(0)
      expect(@lmx.condition_date).to be_nil
    end

    it 'should create MachineConditions' do
      @lmx.update_condition('foo')

      expect(MachineCondition.all.count).to eq(1)
      expect(MachineCondition.first.comment).to eq('foo')
    end

    it 'should tag update with a user when given' do
      @lmx.update_condition('foo', user_id: FactoryBot.create(:user, id: 10, username: 'foo').id)

      expect(@lmx.user_id).to eq(10)
      expect(@lmx.last_updated_by_username).to eq('foo')
    end
  end

  describe '#destroy' do
    it 'works with regionless locations' do
      regionless_location = FactoryBot.create(:location, name: 'Regionless Location', region: nil)
      regionless_lmx = FactoryBot.create(:location_machine_xref, location: regionless_location, machine: @m)

      expect(Pony).to_not receive(:mail)

      user = User.find(1)
      regionless_lmx.destroy(user_id: user.id)

      expect(LocationMachineXref.all).to_not include(regionless_lmx)
      submission = UserSubmission.fourth

      expect(submission.region).to eq(nil)
      expect(submission.user).to eq(user)
      expect(submission.location).to eq(regionless_lmx.location)
      expect(submission.machine).to eq(regionless_lmx.machine)
      expect(submission.submission).to eq("#{@m.name} was removed from #{regionless_location.name} by #{user.name}")
      expect(submission.submission_type).to eq(UserSubmission::REMOVE_MACHINE_TYPE)
    end

    it 'should remove the lmx, and email admins if appropriate' do
      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          body: "Cool Bar\nSassy\nPortland\n(user_id: 1) (entered from  via  by ssw (foo@bar.com))",
          subject: 'PBM - Someone removed a machine from a location',
          to: ['foo@bar.com'],
          from: 'admin@pinballmap.com'
        )
      end

      @lmx.destroy(user_id: 1)

      expect(Pony).to receive(:mail) do |mail|
        expect(mail).to include(
          body: "Cool Bar\nSassy\nPortland\n(user_id: ) (entered from 0.0.0.0 via cleOS)",
          subject: 'PBM - Someone removed a machine from a location',
          to: ['foo@bar.com'],
          from: 'admin@pinballmap.com'
        )
      end

      @lmx.destroy(remote_ip: '0.0.0.0', user_agent: 'cleOS')

      expect(Pony).to_not receive(:mail)

      @lmx_no_email.destroy

      expect(LocationMachineXref.all).to eq([])
    end

    it 'should not send an email if the region is set for digest removals' do
      r_digest_email = FactoryBot.create(:region, should_email_machine_removal: 1, send_digest_removal_emails: 1, send_digest_comment_emails: 1)
      u_digest_email = FactoryBot.create(:user, id: 2, region: r_digest_email, username: 'cibw', email: 'foo@baz.com')
      l_digest_email = FactoryBot.create(:location, region: r_digest_email)
      lmx_digest_email = FactoryBot.create(:location_machine_xref, location: l_digest_email, machine: @m)

      expect(Pony).to_not receive(:mail)

      lmx_digest_email.destroy(user_id: u_digest_email.id)
    end

    it 'auto-creates a user submission' do
      user = User.find(1)
      @lmx.destroy(user_id: user.id)

      submission = UserSubmission.third

      expect(submission.region).to eq(@l.region)
      expect(submission.user).to eq(user)
      expect(submission.location).to eq(@lmx.location)
      expect(submission.machine).to eq(@lmx.machine)
      expect(submission.submission).to eq("#{@m.name} was removed from #{@l.name} by #{user.name}")
      expect(submission.submission_type).to eq(UserSubmission::REMOVE_MACHINE_TYPE)
    end
  end

  describe '#current_condition' do
    it 'should return the most recent machine condition' do
      @r = FactoryBot.create(:region, name: 'Portland', should_email_machine_removal: 1)
      @l = FactoryBot.create(:location, region: @r, name: 'Cool Bar')
      @m = FactoryBot.create(:machine, name: 'Sassy')
      @lmx = FactoryBot.create(:location_machine_xref, location: @l, machine: @m)

      FactoryBot.create(:machine_condition, location_machine_xref: @lmx, comment: 'foo')
      FactoryBot.create(:machine_condition, location_machine_xref: @lmx, comment: 'bar')
      FactoryBot.create(:machine_condition, location_machine_xref: @lmx, comment: 'baz')

      expect(@lmx.current_condition.comment).to eq('baz')
    end
  end

  describe '#last_updated_by_username' do
    it 'should return the most recent comments username' do
      lmx = FactoryBot.create(:location_machine_xref)

      expect(lmx.last_updated_by_username).to eq('')

      lmx = FactoryBot.create(:location_machine_xref, user: FactoryBot.create(:user, id: 666, username: 'foo'))

      expect(lmx.last_updated_by_username).to eq('foo')
    end
  end

  describe '#create' do
    it 'auto-creates a user submission' do
      user = FactoryBot.create(:user, id: 777)

      FactoryBot.create(:location_machine_xref, location: @l, machine: @m, user: user)

      submission = UserSubmission.third

      expect(submission.region).to eq(@l.region)
      expect(submission.user).to eq(user)
      expect(submission.location).to eq(@l)
      expect(submission.machine).to eq(@m)
      expect(submission.submission).to eq("#{@m.name} was added to #{@l.name} by #{user.name}")
      expect(submission.submission_type).to eq(UserSubmission::NEW_LMX_TYPE)
    end
  end

  describe '#current_condition' do
    it 'should return the most recent machine condition' do
      @r = FactoryBot.create(:region, name: 'Portland', should_email_machine_removal: 1)
      @l = FactoryBot.create(:location, region: @r, name: 'Cool Bar')
      @m = FactoryBot.create(:machine, name: 'Sassy')
      @lmx = FactoryBot.create(:location_machine_xref, location: @l, machine: @m)

      FactoryBot.create(:machine_condition, location_machine_xref: @lmx, comment: 'foo')
      FactoryBot.create(:machine_condition, location_machine_xref: @lmx, comment: 'bar')
      FactoryBot.create(:machine_condition, location_machine_xref: @lmx, comment: 'baz')

      expect(@lmx.current_condition.comment).to eq('baz')
    end
  end

  describe '#last_updated_by_username' do
    it 'should return the most recent comments username' do
      lmx = FactoryBot.create(:location_machine_xref)

      expect(lmx.last_updated_by_username).to eq('')

      lmx = FactoryBot.create(:location_machine_xref, user: FactoryBot.create(:user, id: 666, username: 'foo'))

      expect(lmx.last_updated_by_username).to eq('foo')
    end
  end
end
