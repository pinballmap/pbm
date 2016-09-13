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
      lmx1 = FactoryGirl.create(:location_machine_xref, location: FactoryGirl.create(:location, name: 'First Location'), machine: FactoryGirl.create(:machine, name: 'First Machine'))
      lmx2 = FactoryGirl.create(:location_machine_xref, location: FactoryGirl.create(:location, name: 'Second Location'), machine: FactoryGirl.create(:machine, name: 'Second Machine'))
      lmx3 = FactoryGirl.create(:location_machine_xref, location: FactoryGirl.create(:location, name: 'Third Location'), machine: FactoryGirl.create(:machine, name: 'Third Machine'))
      FactoryGirl.create(:machine_score_xref, user: @user, score: 100, location_machine_xref: lmx1, created_at: 'Jan-01-2016')
      FactoryGirl.create(:machine_score_xref, user: @user, score: 200, location_machine_xref: lmx2, created_at: 'Jan-02-2016')
      FactoryGirl.create(:machine_score_xref, user: @user, score: 300, location_machine_xref: lmx3, created_at: 'Jan-03-2016')

      expect(@user.profile_list_of_high_scores).to eq("<span class='score_machine'>First Machine</span><span class='score_score'>100</span><span class='score_meta'>at </span><span class='score_meta_gen'>First Location</span> <span class='score_meta'> on </span><span class='score_meta_gen'>Jan-01-2016</span><br /><br /><span class='score_machine'>Second Machine</span><span class='score_score'>200</span><span class='score_meta'>at </span><span class='score_meta_gen'>Second Location</span> <span class='score_meta'> on </span><span class='score_meta_gen'>Jan-02-2016</span><br /><br /><span class='score_machine'>Third Machine</span><span class='score_score'>300</span><span class='score_meta'>at </span><span class='score_meta_gen'>Third Location</span> <span class='score_meta'> on </span><span class='score_meta_gen'>Jan-03-2016</span>")
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

      expect(@user.profile_list_of_edited_locations('localhost:8080')).to eq("<span class='location_edited'><a href='http://localhost:8080/portland/?by_location_id=1'>foo</a></span><br /><span class='location_edited'><a href='http://localhost:8080/portland/?by_location_id=2'>bar</a></span>")
    end

    it 'should not return locations that no longer exist' do
      location = FactoryGirl.create(:location, id: 1, name: 'foo')

      FactoryGirl.create(:user_submission, user: @user, location: location, submission_type: UserSubmission::NEW_CONDITION_TYPE)
      FactoryGirl.create(:user_submission, user: @user, location_id: -1, submission_type: UserSubmission::NEW_CONDITION_TYPE)

      expect(@user.profile_list_of_edited_locations('localhost:8080')).to eq("<span class='location_edited'><a href='http://localhost:8080/portland/?by_location_id=1'>foo</a></span>")
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
