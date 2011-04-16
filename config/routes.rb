regions = 'portland|chicago'

if (Region.table_exists? && Region.all.size > 0)
  regions = Region.all.each.collect {|r| r.name}.join('|')
end

Pbm::Application.routes.draw do
  scope ':region', :constraints => { :region => /#{regions}/i } do
    devise_for :users

    resources :pages
    resources :events
    resources :regions
    resources :locations
    resources :machines

    resources :machine_score_xrefs
    resources :location_machine_xrefs do
      collection do
        get :update_machine_condition
      end
    end

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

    match 'locations/:id/render_scores'   => 'locations#render_scores'
    match 'locations/:id/render_machines' => 'locations#render_machines'

    match '*page', :to => 'locations#unknown_route'
  end

  resources :location_picture_xrefs
  resources :locations, :machines do
    collection do
      get :autocomplete
    end
  end

  get 'pages/home'
  root :to => 'pages#home'
end
