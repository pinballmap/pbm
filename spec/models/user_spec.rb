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
    it "should return a formatted list of the user's high scores for their profile page" do
      region = FactoryGirl.create(:region)

      FactoryGirl.create(:user_submission, region: region, location: FactoryGirl.create(:location, name: 'First Location'), machine: FactoryGirl.create(:machine, name: 'First Machine'), submission_type: UserSubmission::NEW_SCORE_TYPE, submission: 'ssw added a score of 100 for First Machine to First Location', user: @user, created_at: '2016-01-01')
      FactoryGirl.create(:user_submission, region: region, location: FactoryGirl.create(:location, name: 'Second Location'), machine: FactoryGirl.create(:machine, name: 'Second Machine'), submission_type: UserSubmission::NEW_SCORE_TYPE, submission: 'ssw added a score of 200 for Second Machine to Second Location', user: @user, created_at: '2016-01-02')

      expect(@user.profile_list_of_high_scores).to eq('First Location, First Machine, 01-01-2016, 100 points<br />Second Location, Second Machine, 01-02-2016, 200 points')
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
    it "should return a formatted list of the user's list of edited locations for their profile page" do
      location = FactoryGirl.create(:location, id: 1, name: 'foo')
      another_location = FactoryGirl.create(:location, id: 2, name: 'bar')

      FactoryGirl.create(:user_submission, user: @user, location: location, submission_type: UserSubmission::NEW_CONDITION_TYPE)
      FactoryGirl.create(:user_submission, user: @user, location: another_location, submission_type: UserSubmission::LOCATION_METADATA_TYPE)

      FactoryGirl.create(:user_submission, user: @user, location: location, submission_type: UserSubmission::LOCATION_METADATA_TYPE)

      expect(@user.profile_list_of_edited_locations('localhost:8080')).to eq("<a href='http://localhost:8080/portland/?by_location_id=1'>foo</a><br /><a href='http://localhost:8080/portland/?by_location_id=2'>bar</a>")
    end

    it 'should not return locations that no longer exist' do
      location = FactoryGirl.create(:location, id: 1, name: 'foo')

      FactoryGirl.create(:user_submission, user: @user, location: location, submission_type: UserSubmission::NEW_CONDITION_TYPE)
      FactoryGirl.create(:user_submission, user: @user, location_id: -1, submission_type: UserSubmission::NEW_CONDITION_TYPE)

      expect(@user.profile_list_of_edited_locations('localhost:8080')).to eq("<a href='http://localhost:8080/portland/?by_location_id=1'>foo</a>")
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
end
