require 'spec_helper'

describe User do
  before(:each) do
    @user = FactoryBot.create(:user)
  end

  describe '#num_machines_added' do
    it 'should return the number of machines this user has added' do
      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::NEW_LMX_TYPE)
      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::NEW_LMX_TYPE)

      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::REMOVE_MACHINE_TYPE)
      FactoryBot.create(:user_submission, user: nil, submission_type: UserSubmission::NEW_LMX_TYPE)

      expect(@user.num_machines_added).to eq(2)
    end
  end

  describe '#num_machines_removed' do
    it 'should return the number of machines this user has removed' do
      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::REMOVE_MACHINE_TYPE)
      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::REMOVE_MACHINE_TYPE)

      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::NEW_LMX_TYPE)
      FactoryBot.create(:user_submission, user: nil, submission_type: UserSubmission::REMOVE_MACHINE_TYPE)

      expect(@user.num_machines_removed).to eq(2)
    end
  end

  describe '#profile_list_of_high_scores' do
    it "should return a list of the user's high scores for their profile page" do
      region = FactoryBot.create(:region)

      FactoryBot.create(:user_submission, region: region, location: FactoryBot.create(:location, name: 'First Location'), machine: FactoryBot.create(:machine, name: 'First Machine'), submission_type: UserSubmission::NEW_SCORE_TYPE, submission: 'ssw added a score of 100 for First Machine to First Location', user: @user, created_at: '2016-01-01')
      FactoryBot.create(:user_submission, region: region, location: FactoryBot.create(:location, name: 'Second Location'), machine: FactoryBot.create(:machine, name: 'Second Machine'), submission_type: UserSubmission::NEW_SCORE_TYPE, submission: 'ssw added a score of 2000 for Second Machine to Second Location', user: @user, created_at: '2016-01-02')

      expect(@user.profile_list_of_high_scores).to eq([['Second Location', 'Second Machine', '2,000', 'Jan-02-2016'], ['First Location', 'First Machine', '100', 'Jan-01-2016']])
    end

    it 'only returns the most recent 50' do
      region = FactoryBot.create(:region)
      @location = FactoryBot.create(:location, name: 'First Location')
      @machine = FactoryBot.create(:machine, name: 'First Machine')

      51.times do |i|
        FactoryBot.create(:user_submission, region: region, location: @location, machine: @machine, submission_type: UserSubmission::NEW_SCORE_TYPE, submission: 'ssw added a score of 100 for First Machine to First Location', user: @user, created_at: Date.new(2016, 1, 1).next_day(i).to_s)
      end

      expect(@user.profile_list_of_high_scores.size).to eq(50)
      expect(@user.profile_list_of_high_scores.map { |s| s[3] }[0]).to eq('Feb-20-2016')
      expect(@user.profile_list_of_high_scores.map { |s| s[3] }[49]).to eq('Jan-02-2016')
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

      expect(@user.num_locations_edited).to eq(6)
    end
  end

  describe '#profile_list_of_edited_locations' do
    it 'should return a list of edited locations for their profile page' do
      location = FactoryBot.create(:location, id: 1, region_id: 100, name: 'foo', created_at: '2017-01-02')
      another_location = FactoryBot.create(:location, id: 2, region_id: 200, name: 'bar', created_at: '2017-01-01')

      FactoryBot.create(:user_submission, user: @user, created_at: '2016-01-01', location: location, submission_type: UserSubmission::NEW_CONDITION_TYPE)
      FactoryBot.create(:user_submission, user: @user, created_at: '2016-01-02', location: another_location, submission_type: UserSubmission::LOCATION_METADATA_TYPE)

      FactoryBot.create(:user_submission, user: @user, location: location, submission_type: UserSubmission::LOCATION_METADATA_TYPE)

      expect(@user.profile_list_of_edited_locations).to eq([[another_location.id, another_location.name, another_location.region_id], [location.id, location.name, location.region_id]])
    end

    it 'should return the most recent 50' do
      51.times do |i|
        FactoryBot.create(:user_submission, user: @user, location: FactoryBot.create(:location, name: i.to_s), submission_type: UserSubmission::LOCATION_METADATA_TYPE, created_at: Date.new(2016, 1, 1).next_day(i).to_s)
      end

      expect(@user.profile_list_of_edited_locations.size).to eq(50)
      expect(@user.profile_list_of_edited_locations.map { |s| s[1] }[0]).to eq('50')
      expect(@user.profile_list_of_edited_locations.map { |s| s[1] }[49]).to eq('1')
    end

    it 'should not return locations that no longer exist' do
      location = FactoryBot.create(:location, id: 1, region_id: 11, name: 'foo')

      FactoryBot.create(:user_submission, user: @user, location: location, submission_type: UserSubmission::NEW_CONDITION_TYPE)
      FactoryBot.create(:user_submission, user: @user, location_id: -1, submission_type: UserSubmission::NEW_CONDITION_TYPE)

      expect(@user.profile_list_of_edited_locations).to eq([[location.id, location.name, location.region_id]])
    end
  end

  describe '#num_locations_suggested' do
    it 'should return the number of locations the user has suggested' do
      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::SUGGEST_LOCATION_TYPE)
      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::SUGGEST_LOCATION_TYPE)

      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::NEW_CONDITION_TYPE)
      FactoryBot.create(:user_submission, user: nil, submission_type: UserSubmission::SUGGEST_LOCATION_TYPE)

      expect(@user.num_locations_suggested).to eq(2)
    end
  end

  describe '#num_lmx_comments_left' do
    it 'should return the number of comments a user has made on lmxes' do
      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::NEW_CONDITION_TYPE)
      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::NEW_CONDITION_TYPE)

      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::SUGGEST_LOCATION_TYPE)
      FactoryBot.create(:user_submission, user: nil, submission_type: UserSubmission::NEW_CONDITION_TYPE)

      expect(@user.num_lmx_comments_left).to eq(2)
    end
  end

  describe '#as_json' do
    it 'should default to only return id' do
      expect(@user.to_json).to eq("{\"id\":#{@user.id}}")
    end

    it 'should allow you to include additional methods' do
      expect(@user.to_json(methods: [:num_machines_added])).to eq("{\"id\":#{@user.id},\"num_machines_added\":0}")
    end
  end
end
