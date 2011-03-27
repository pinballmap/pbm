regions = Region.all.empty? ? 'portland' : Region.all.each.collect {|r| r.name}.join('|')

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

    match '/' => "pages#region"
    match '/about' => 'pages#about'
    match '/apps' => 'pages#apps'
    match '/appsupport' => 'pages#appsupport'
    match '/contact' => 'pages#contact'
    match '/links' => 'pages#links'
    match '/newlocation' => 'pages#newlocation'
    match '/highrollers' => 'pages#highrollers'

    match 'locations/:id/render_scores'   => 'locations#render_scores'
    match 'locations/:id/render_machines' => 'locations#render_machines'

    match '*page', :to => 'locations#unknown_route'
  end

  resources :location_picture_xrefs

  resources :locations, :machines do
    get :autocomplete, :on => :collection
  end

  get 'pages/home'
  root :to => 'pages#home'
end
