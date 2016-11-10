require 'spec_helper'

describe PagesHelper, type: :helper do
  describe '#other_regions_html' do
    it 'should give me html of links to other regions landing pages' do
      r = FactoryGirl.create(:region)
      FactoryGirl.create(:region, name: 'Xanadu', full_name: 'Xanadu, FL')
      FactoryGirl.create(:region, name: 'Anaconda', full_name: 'Anaconda, MI')

      expect(helper.other_regions_html(r)).to eq("<li><a href='/anaconda'>Anaconda, MI</a></li><li><a href='/xanadu'>Xanadu, FL</a></li>")
    end
  end

  describe '#title_for_path' do
    describe 'without region' do
      it 'displays the correct app title' do
        expect(helper.title_for_path(apps_path)).to eq('App - Pinball Map')
      end

      it 'displays the correct app support title' do
        expect(helper.title_for_path(apps_support_path)).to eq('App Support - Pinball Map')
      end

      it 'displays the correct faq title' do
        expect(helper.title_for_path(faq_path)).to eq('FAQ - Pinball Map')
      end

      it 'displays the correct store title ' do
        expect(helper.title_for_path(store_path)).to eq('Store - T-Shirts for Sale! - Pinball Map')
      end

      it 'displays the profile title' do
        expect(helper.title_for_path(profile_user_path(11))).to eq('User Profile - Pinball Map')
      end

      it 'displays the donate title' do
        expect(helper.title_for_path(donate_path)).to eq('Donate - Pinball Map')
      end

      it 'displays the login title' do
        expect(helper.title_for_path('/login')).to eq('Login - Pinball Map')
      end

      it 'displays the join title' do
        expect(helper.title_for_path('/join')).to eq('Join - Pinball Map')
      end

      it 'displays the forgot password title' do
        expect(helper.title_for_path('/password')).to eq('Forgot Password - Pinball Map')
      end

      it 'displays the confirmation instructions title' do
        expect(helper.title_for_path('/confirmation')).to eq('Confirmation Instructions - Pinball Map')
      end

      it 'displays the default title' do
        expect(helper.title_for_path('/foo')).to eq('Pinball Map')
      end
    end

    describe 'with region' do
      before(:each) do
        @region = FactoryGirl.create(:region, name: 'portland', full_name: 'Portland')
      end

      it 'displays the suggest locations title' do
        expect(helper.title_for_path(suggest_path(@region.name), @region)).to eq('Suggest a New Location to the ' + @region.full_name + ' Pinball Map')
      end

      it 'displays the about title' do
        expect(helper.title_for_path(about_path(@region.name), @region)).to eq('About the ' + @region.full_name + ' Pinball Map')
      end

      it 'displays the events title' do
        expect(helper.title_for_path(events_path(@region.name), @region)).to eq('Upcoming Events - ' + @region.full_name + ' Pinball Map')
      end

      it 'displays the high scores title' do
        expect(helper.title_for_path(high_rollers_path(@region.name), @region)).to eq('High Scores - ' + @region.full_name + ' Pinball Map')
      end
    end
  end
end
