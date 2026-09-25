require 'spec_helper'

describe UserSubmission do
  describe '.activity_scope' do
    before(:each) do
      @user = FactoryBot.create(:user, username: 'ssw', email: 'ssw@ok.com')
      @other_user = FactoryBot.create(:user, username: 'other', email: 'other@ok.com')

      @own_score = FactoryBot.create(:user_submission, submission_type: 'new_msx', user: @user)
      @other_score = FactoryBot.create(:user_submission, submission_type: 'new_msx', user: @other_user)
      @new_lmx = FactoryBot.create(:user_submission, submission_type: 'new_lmx', user: @other_user)
      FactoryBot.create(:user_submission, submission_type: 'new_msx', user: @other_user, deleted_at: Date.today)
      FactoryBot.create(:user_submission, submission_type: 'new_lmx', user: @other_user, deleted_at: Date.today)
    end

    it 'returns only the current user scores for new_msx' do
      expect(UserSubmission.activity_scope([ 'new_msx' ], @user)).to contain_exactly(@own_score)
    end

    it 'returns nothing for new_msx when logged out' do
      expect(UserSubmission.activity_scope([ 'new_msx' ], nil)).to be_empty
    end

    it 'returns every user score for all_msx, logged in or out' do
      expect(UserSubmission.activity_scope([ 'all_msx' ], @user)).to contain_exactly(@own_score, @other_score)
      expect(UserSubmission.activity_scope([ 'all_msx' ], nil)).to contain_exactly(@own_score, @other_score)
    end

    it 'lets all_msx take precedence when combined with new_msx' do
      expect(UserSubmission.activity_scope([ 'new_msx', 'all_msx' ], @user)).to contain_exactly(@own_score, @other_score)
    end

    it 'combines all_msx with other submission types and excludes deleted submissions' do
      expect(UserSubmission.activity_scope([ 'all_msx', 'new_lmx' ], nil)).to contain_exactly(@own_score, @other_score, @new_lmx)
    end

    it 'returns nothing when no types are requested' do
      expect(UserSubmission.activity_scope([], @user)).to be_empty
    end
  end
end
