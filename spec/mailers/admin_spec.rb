require 'spec_helper'

RSpec.describe AdminMailer, type: :mailer do
  describe 'weekly_admin_digest_regionless' do
    # it 'should send an email' do
    #   email = AdminMailer.with(user: 'foo@bar.com', machines_count: 1, locations_count: 1, machineless_locations: 'Sassy House', suggested_locations: 'Lounge Bar', suggested_locations_count: 1, locations_added_count: 1, locations_deleted_count: 1, machine_comments_count: 1, machines_added_count: 1, machines_removed_count: 1, subject: 'Pinball Map - Weekly admin REGIONLESS digest').weekly_admin_digest_regionless

    #   assert_emails 1 do
    #     email.deliver_now
    #   end

    #   assert_equal ['admin@pinballmap.com'], email.from
    #   assert_equal ['foo@bar.com'], email.to
    #   assert_equal 'Pinball Map - Weekly admin REGIONLESS digest', email.subject
    # end

    # let(:mail) { AdminMailer.weekly_admin_digest_regionless }

    # it 'renders the headers' do
    #   expect(mail.subject).to include('Pinball Map - Weekly admin REGIONLESS digest')
    #   # expect(mail.to).to eq(['to@example.org'])
    #   expect(mail.from).to eq(['admin@pinballmap.com'])
    # end

    # it 'renders the body' do
    #   expect(mail.body.encoded).to match('Here is a weekly overview of regionless locations')
    # end
  end
end
