require 'spec_helper'

describe User do
  before(:each) do
    @user = FactoryGirl.create(:user)
  end

  describe '#num_machines_added' do
    it 'should return the number of machines this user has added' do
      FactoryGirl.create(:user_submission, user: @user, submission_type: UserSubmission::NEW_LMX_TYPE)
      FactoryGirl.create(:user_submission, user: @user, submission_type: UserSubmission::NEW_LMX_TYPE)

      FactoryGirl.create(:user_submission, user: @user, submission_type: UserSubmission::REMOVE_MACHINE_TYPE)
      FactoryGirl.create(:user_submission, user: nil, submission_type: UserSubmission::NEW_LMX_TYPE)

      expect(@user.num_machines_added).to eq(2)
    end
  end

  describe '#num_machines_removed' do
    it 'should return the number of machines this user has removed' do
      FactoryGirl.create(:user_submission, user: @user, submission_type: UserSubmission::REMOVE_MACHINE_TYPE)
      FactoryGirl.create(:user_submission, user: @user, submission_type: UserSubmission::REMOVE_MACHINE_TYPE)

      FactoryGirl.create(:user_submission, user: @user, submission_type: UserSubmission::NEW_LMX_TYPE)
      FactoryGirl.create(:user_submission, user: nil, submission_type: UserSubmission::REMOVE_MACHINE_TYPE)

      expect(@user.num_machines_removed).to eq(2)
    end
  end

  describe '#profile_list_of_high_scores' do
    it "should return a list of the user's high scores for their profile page" do
      region = FactoryGirl.create(:region)

      FactoryGirl.create(:user_submission, region: region, location: FactoryGirl.create(:location, name: 'First Location'), machine: FactoryGirl.create(:machine, name: 'First Machine'), submission_type: UserSubmission::NEW_SCORE_TYPE, submission: 'ssw added a score of 100 for First Machine to First Location', user: @user, created_at: '2016-01-01')
      FactoryGirl.create(:user_submission, region: region, location: FactoryGirl.create(:location, name: 'Second Location'), machine: FactoryGirl.create(:machine, name: 'Second Machine'), submission_type: UserSubmission::NEW_SCORE_TYPE, submission: 'ssw added a score of 2000 for Second Machine to Second Location', user: @user, created_at: '2016-01-02')

      expect(@user.profile_list_of_high_scores).to eq([['First Location', 'First Machine', '100', 'Jan-01-2016'], ['Second Location', 'Second Machine', '2,000', 'Jan-02-2016']])
    end
  end

  describe '#num_locations_edited' do
    it 'should return the number of locations the user has edited' do
      dupe_location = FactoryGirl.create(:location, id: 100)
      FactoryGirl.create(:user_submission, user: @user, location: FactoryGirl.create(:location, id: 200), submission_type: UserSubmission::NEW_CONDITION_TYPE)
      FactoryGirl.create(:user_submission, user: @user, location: FactoryGirl.create(:location, id: 300), submission_type: UserSubmission::LOCATION_METADATA_TYPE)
      FactoryGirl.create(:user_submission, user: @user, location: FactoryGirl.create(:location, id: 400), submission_type: UserSubmission::NEW_LMX_TYPE)
      FactoryGirl.create(:user_submission, user: @user, location: dupe_location, submission_type: UserSubmission::REMOVE_MACHINE_TYPE)
      FactoryGirl.create(:user_submission, user: @user, location: FactoryGirl.create(:location, id: 500), submission_type: UserSubmission::NEW_SCORE_TYPE)
      FactoryGirl.create(:user_submission, user: @user, location: FactoryGirl.create(:location, id: 600), submission_type: UserSubmission::CONFIRM_LOCATION_TYPE)

      FactoryGirl.create(:user_submission, user: @user, location: dupe_location, machine: FactoryGirl.create(:machine), submission_type: UserSubmission::REMOVE_MACHINE_TYPE)
      FactoryGirl.create(:user_submission, user: @user, submission_type: UserSubmission::REMOVE_MACHINE_TYPE)
      FactoryGirl.create(:user_submission, user: @user, submission_type: UserSubmission::SUGGEST_LOCATION_TYPE)
      FactoryGirl.create(:user_submission, user: nil, submission_type: UserSubmission::NEW_CONDITION_TYPE)

      expect(@user.num_locations_edited).to eq(6)
    end
  end

  describe '#profile_list_of_edited_locations' do
    it 'should return a list of edited locations for their profile page' do
      location = FactoryGirl.create(:location, id: 1, region_id: 100, name: 'foo')
      another_location = FactoryGirl.create(:location, id: 2, region_id: 200, name: 'bar')

      FactoryGirl.create(:user_submission, user: @user, created_at: '2016-01-01', location: location, submission_type: UserSubmission::NEW_CONDITION_TYPE)
      FactoryGirl.create(:user_submission, user: @user, created_at: '2016-01-02', location: another_location, submission_type: UserSubmission::LOCATION_METADATA_TYPE)

      FactoryGirl.create(:user_submission, user: @user, location: location, submission_type: UserSubmission::LOCATION_METADATA_TYPE)

      expect(@user.profile_list_of_edited_locations).to eq([[another_location.id, another_location.name, another_location.region_id], [location.id, location.name, location.region_id]])
    end

    it 'should not return locations that no longer exist' do
      location = FactoryGirl.create(:location, id: 1, region_id: 11, name: 'foo')

      FactoryGirl.create(:user_submission, user: @user, location: location, submission_type: UserSubmission::NEW_CONDITION_TYPE)
      FactoryGirl.create(:user_submission, user: @user, location_id: -1, submission_type: UserSubmission::NEW_CONDITION_TYPE)

      expect(@user.profile_list_of_edited_locations).to eq([[location.id, location.name, location.region_id]])
    end
  end

  describe '#num_locations_suggested' do
    it 'should return the number of locations the user has suggested' do
      FactoryGirl.create(:user_submission, user: @user, submission_type: UserSubmission::SUGGEST_LOCATION_TYPE)
      FactoryGirl.create(:user_submission, user: @user, submission_type: UserSubmission::SUGGEST_LOCATION_TYPE)

      FactoryGirl.create(:user_submission, user: @user, submission_type: UserSubmission::NEW_CONDITION_TYPE)
      FactoryGirl.create(:user_submission, user: nil, submission_type: UserSubmission::SUGGEST_LOCATION_TYPE)

      expect(@user.num_locations_suggested).to eq(2)
    end
  end

  describe '#num_lmx_comments_left' do
    it 'should return the number of comments a user has made on lmxes' do
      FactoryGirl.create(:user_submission, user: @user, submission_type: UserSubmission::NEW_CONDITION_TYPE)
      FactoryGirl.create(:user_submission, user: @user, submission_type: UserSubmission::NEW_CONDITION_TYPE)

      FactoryGirl.create(:user_submission, user: @user, submission_type: UserSubmission::SUGGEST_LOCATION_TYPE)
      FactoryGirl.create(:user_submission, user: nil, submission_type: UserSubmission::NEW_CONDITION_TYPE)

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
