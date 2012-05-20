regions = 'portland|chicago'

if (Region.table_exists? && Region.all.size > 0)
  regions = Region.all.each.collect {|r| r.name}.join('|')
end

Pbm::Application.routes.draw do
  

  

  

  mount RailsAdmin::Engine => '/admin', :as => 'rails_admin'

  scope ':region', :constraints => { :region => /#{regions}|!admin/i } do
    resources :pages
    resources :events
    resources :regions

    resources :machines do
      collection do
        get :autocomplete
      end
    end

    resources :machine_score_xrefs

    resources :location_machine_xrefs do
      collection do
        get :update_machine_condition
      end
    end

    resources :locations do
      collection do
        get :update_desc
        get :autocomplete
      end
    end

    match 'locations/:id/locations_for_machine' => 'locations#locations_for_machine'
    match 'locations/:id/render_scores'   => 'locations#render_scores'
    match 'locations/:id/render_machines' => 'locations#render_machines'
    match 'locations/:id/render_add_machine' => 'locations#render_add_machine'
    match 'locations/:id/render_desc' => 'locations#render_desc'

    match 'location_machine_xrefs/:id/create_confirmation' => 'location_machine_xrefs#create_confirmation'
    match 'location_machine_xrefs/:id/remove_confirmation' => 'location_machine_xrefs#remove_confirmation'
    match 'location_machine_xrefs/:id/render_machine_condition' => 'location_machine_xrefs#render_machine_condition'
    match 'location_machine_xrefs/:id/condition_update_confirmation' => 'location_machine_xrefs#condition_update_confirmation'

    match ':region' + '.rss' => 'location_machine_xrefs#index', :format => 'xml'
    match ':region' + '_scores.rss' => 'machine_score_xrefs#index', :format => 'xml'

    match '/' => "pages#region", :as => 'region_homepage'
    match '/about' => 'pages#about'
    match '/apps' => 'pages#apps'
    match '/app_support' => 'pages#app_support'
    match '/contact' => 'pages#contact'
    match '/contact_sent' => 'pages#contact_sent'
    match '/links' => 'pages#links'
    match '/high_rollers' => 'pages#high_rollers'
    match '/suggest_new_location' => 'pages#suggest_new_location'
    match '/submitted_new_location' => 'pages#submitted_new_location'

    match 'iphone.html', :to => 'locations#mobile'
    match '*page', :to => 'locations#unknown_route'
  end

  resources :location_picture_xrefs

  devise_for :users

  match 'iphone.html', :to => 'locations#mobile'
  get 'pages/home'
  root :to => 'pages#home'
end
