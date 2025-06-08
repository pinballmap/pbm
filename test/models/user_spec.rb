require 'spec_helper'

describe User do
  before(:each) do
    @user = FactoryBot.create(:user)
  end

  describe 'rails admin scopes' do
    it 'should show admins and non_admins based on scopes' do
      admin_user = FactoryBot.create(:user, region_id: 1)

      expect(User.admins).must_equal [admin_user]
      expect(User.non_admins).must_equal [@user]
    end
  end

  describe '#render_user_flag' do
    it 'should return the user selected flag' do
      flag_user = FactoryBot.create(:user, username: 'ssw', flag: 'us-ca')

      expect(flag_user.flag).to eq('us-ca')
    end
  end

  describe '#num_machines_added' do
    it 'should return the number of machines this user has added' do
      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::NEW_LMX_TYPE)
      @user.update_column(:num_machines_added, 1)
      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::NEW_LMX_TYPE)
      @user.update_column(:num_machines_added, 2)

      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::REMOVE_MACHINE_TYPE)
      @user.update_column(:num_machines_removed, 1)
      FactoryBot.create(:user_submission, user: nil, submission_type: UserSubmission::NEW_LMX_TYPE)

      expect(@user.num_machines_added).must_equal 2
    end
  end

  describe '#num_machines_removed' do
    it 'should return the number of machines this user has removed' do
      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::REMOVE_MACHINE_TYPE)
      @user.update_column(:num_machines_removed, 1)
      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::REMOVE_MACHINE_TYPE)
      @user.update_column(:num_machines_removed, 2)

      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::NEW_LMX_TYPE)
      @user.update_column(:num_machines_added, 1)
      FactoryBot.create(:user_submission, user: nil, submission_type: UserSubmission::REMOVE_MACHINE_TYPE)

      expect(@user.num_machines_removed).must_equal 2
    end
  end

  describe '#profile_list_of_high_scores' do
    it "should return a list of the user's high scores for their profile page" do
      region = FactoryBot.create(:region)

      FactoryBot.create(:user_submission, region: region, location: FactoryBot.create(:location, name: 'First Location'), machine: FactoryBot.create(:machine, name: 'First Machine'), submission_type: UserSubmission::NEW_SCORE_TYPE, submission: 'ssw added a high score of 100 on First Machine at First Location', user: @user, created_at: '2016-01-01')
      FactoryBot.create(:user_submission, region: region, location: FactoryBot.create(:location, name: 'Second Location'), machine: FactoryBot.create(:machine, name: 'Second Machine'), submission_type: UserSubmission::NEW_SCORE_TYPE, submission: 'ssw added a high score of 2000 on Second Machine at Second Location', user: @user, created_at: '2016-01-02')

      expect(@user.profile_list_of_high_scores).must_equal [['Second Location', 'Second Machine', '2,000', 'Jan 02, 2016'], ['First Location', 'First Machine', '100', 'Jan 01, 2016']]
    end

    it 'only returns the most recent 50' do
      region = FactoryBot.create(:region)
      @location = FactoryBot.create(:location, name: 'First Location')

      51.times do |i|
        machine = FactoryBot.create(:machine, name: "Machine #{i}")
        FactoryBot.create(:user_submission, region: region, location: @location, machine: machine, submission_type: UserSubmission::NEW_SCORE_TYPE, submission: "ssw added a high score of 100 on #{machine.name} at First Location", user: @user, created_at: Date.new(2016, 1, 1).next_day(i).to_s)
      end

      expect(@user.profile_list_of_high_scores.length).must_equal 50
      expect(@user.profile_list_of_high_scores.map { |s| s[3] }[0]).must_equal 'Feb 20, 2016'
      expect(@user.profile_list_of_high_scores.map { |s| s[3] }[49]).must_equal 'Jan 02, 2016'
    end

    it 'returns the highest score per machine' do
      region = FactoryBot.create(:region)
      location = FactoryBot.create(:location, name: 'First Location')
      use_this_location = FactoryBot.create(:location, name: 'Second Location')
      machine = FactoryBot.create(:machine, name: 'First Machine')

      FactoryBot.create(:user_submission, region: region, location: location, machine: machine, submission_type: UserSubmission::NEW_SCORE_TYPE, submission: 'ssw added a high score of 100 on First Machine at First Location', user: @user, created_at: Date.new(2016, 1, 1))
      FactoryBot.create(:user_submission, region: region, location: use_this_location, machine: machine, submission_type: UserSubmission::NEW_SCORE_TYPE, submission: 'ssw added a high score of 300 on First Machine at Second Location', user: @user, created_at: Date.new(2016, 1, 1))
      FactoryBot.create(:user_submission, region: region, location: use_this_location, machine: machine, submission_type: UserSubmission::NEW_SCORE_TYPE, submission: 'ssw added a high score of 2,000 on First Machine at Second Location', user: @user, created_at: Date.new(2016, 1, 1))

      expect(@user.profile_list_of_high_scores.size).must_equal 1
      expect(@user.profile_list_of_high_scores).must_equal [['Second Location', 'First Machine', '2,000', 'Jan 01, 2016']]
    end
  end

  describe '#num_locations_edited' do
    it 'should return the number of locations the user has edited' do
      dupe_location = FactoryBot.create(:location, id: 100)
      FactoryBot.create(:user_submission, user: @user, location: FactoryBot.create(:location, id: 200), submission_type: UserSubmission::NEW_CONDITION_TYPE)
      FactoryBot.create(:user_submission, user: @user, location: FactoryBot.create(:location, id: 300), submission_type: UserSubmission::LOCATION_METADATA_TYPE)
      FactoryBot.create(:user_submission, user: @user, location: FactoryBot.create(:location, id: 400), submission_type: UserSubmission::NEW_LMX_TYPE)
      FactoryBot.create(:user_submission, user: @user, location: dupe_location, submission_type: UserSubmission::REMOVE_MACHINE_TYPE)
      FactoryBot.create(:user_submission, user: @user, location: FactoryBot.create(:location, id: 500), submission_type: UserSubmission::NEW_SCORE_TYPE)
      FactoryBot.create(:user_submission, user: @user, location: FactoryBot.create(:location, id: 600), submission_type: UserSubmission::CONFIRM_LOCATION_TYPE)

      FactoryBot.create(:user_submission, user: @user, location: dupe_location, machine: FactoryBot.create(:machine), submission_type: UserSubmission::REMOVE_MACHINE_TYPE)
      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::REMOVE_MACHINE_TYPE)
      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::SUGGEST_LOCATION_TYPE)
      FactoryBot.create(:user_submission, user: nil, submission_type: UserSubmission::NEW_CONDITION_TYPE)

      expect(@user.num_locations_edited).must_equal 6
    end
  end

  describe '#profile_list_of_edited_locations' do
    it 'should return a list of edited locations for their profile page' do
      location = FactoryBot.create(:location, id: 1, region_id: 100, name: 'foo', created_at: '2017-01-02')
      another_location = FactoryBot.create(:location, id: 2, region_id: 200, name: 'bar', created_at: '2017-01-01')
      machine = FactoryBot.create(:machine, name: 'First Machine')

      FactoryBot.create(:user_submission, user: @user, created_at: '2018-01-01', machine: machine, location: location, submission_type: UserSubmission::NEW_CONDITION_TYPE, submission: 'ssw added a high score of 100 on First Machine at First Location', location_name: 'foo', location_id: 1)
      FactoryBot.create(:user_submission, user: @user, created_at: '2018-01-02', location: another_location, submission_type: UserSubmission::LOCATION_METADATA_TYPE, location_name: 'bar', location_id: 2)
      FactoryBot.create(:user_submission, user: @user, location: location, submission_type: UserSubmission::LOCATION_METADATA_TYPE, location_name: 'foo', location_id: 1)

      expect(@user.profile_list_of_edited_locations).must_equal [[1, 'foo'], [2, 'bar']]
    end

    it 'should return the most recent 50' do
      51.times do |i|
        location = FactoryBot.create(:location, name: "Location #{i}", id: i.to_i)
        FactoryBot.create(:user_submission, user: @user, location: location, submission_type: UserSubmission::LOCATION_METADATA_TYPE, location_name: location.name, location_id: location.id, created_at: '2017-01-01')
      end

      expect(@user.profile_list_of_edited_locations.length).must_equal 50
      expect(@user.profile_list_of_edited_locations.map { |s| s[1] }[0]).must_equal 'Location 0'
      expect(@user.profile_list_of_edited_locations.map { |s| s[1] }[49]).must_equal 'Location 49'
    end

    it 'should not return locations that no longer exist' do
      location = FactoryBot.create(:location, id: 1, region_id: 11, name: 'foo')

      FactoryBot.create(:user_submission, user: @user, location: location, submission_type: UserSubmission::NEW_CONDITION_TYPE, location_name: 'foo', location_id: 1)
      FactoryBot.create(:user_submission, user: @user, location_id: -1, submission_type: UserSubmission::NEW_CONDITION_TYPE, location_name: nil)

      expect(@user.profile_list_of_edited_locations).must_equal [[location.id, location.name]]
    end
  end

  describe '#num_locations_suggested' do
    it 'should return the number of locations the user has suggested' do
      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::SUGGEST_LOCATION_TYPE)
      @user.update_column(:num_locations_suggested, 1)
      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::SUGGEST_LOCATION_TYPE)
      @user.update_column(:num_locations_suggested, 2)

      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::NEW_CONDITION_TYPE)
      @user.update_column(:num_lmx_comments_left, 1)
      FactoryBot.create(:user_submission, user: nil, submission_type: UserSubmission::SUGGEST_LOCATION_TYPE)

      expect(@user.num_locations_suggested).must_equal 2
    end
  end

  describe '#num_lmx_comments_left' do
    it 'should return the number of comments a user has made on lmxes' do
      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::NEW_CONDITION_TYPE)
      @user.update_column(:num_lmx_comments_left, 1)
      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::NEW_CONDITION_TYPE)
      @user.update_column(:num_lmx_comments_left, 2)

      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::SUGGEST_LOCATION_TYPE)
      @user.update_column(:num_locations_suggested, 1)
      FactoryBot.create(:user_submission, user: nil, submission_type: UserSubmission::NEW_CONDITION_TYPE)

      expect(@user.num_lmx_comments_left).must_equal 2
    end
  end

  describe '#user_submissions_count' do
    it 'should return the total number of user submissions by the user' do
      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::NEW_CONDITION_TYPE)
      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::REMOVE_MACHINE_TYPE)
      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::LOCATION_METADATA_TYPE)
      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::NEW_LMX_TYPE)
      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::NEW_SCORE_TYPE)
      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::CONFIRM_LOCATION_TYPE)
      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::SUGGEST_LOCATION_TYPE)

      expect(@user.user_submissions_count).must_equal 7
    end

    it 'should assign a contributor_rank after 50 user submissions' do
      51.times do
        FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::NEW_LMX_TYPE)
      end

      expect(@user.user_submissions_count).to eq(51)
      expect(@user.contributor_rank).to eq("Super Mapper")
    end
  end

  describe '#as_json' do
    it 'should default to only return id' do
      expect(@user.to_json).must_equal "{\"id\":#{@user.id}}"
    end

    it 'should allow you to include additional methods' do
      expect(@user.to_json(methods: [:num_machines_edited])).must_equal "{\"id\":#{@user.id},\"num_machines_edited\":0}"
    end
  end
end
