Pbm::Application.routes.draw do
  scope ':region', :constraints => { :region => /portland|chicago/i } do
    resources :pages
    resources :regions
    resources :machines
    resources :locations do
      collection do
        get :update_machine_condition
      end
    end

    match 'locations/:id/render_scores'   => 'locations#render_scores'
    match 'locations/:id/render_machines' => 'locations#render_machines'

    match '/' => "pages#region"

    match '*page', :to => 'locations#unknown_route'
  end

  devise_for :users

  resources :location_machine_xrefs, :only => [:create, :destroy]
  resources :machine_score_xrefs,    :only => [:create]

  resources :location_machine_xrefs do
    collection do
      get :update_machine_condition
    end
  end

  resources :locations, :machines do
    get :autocomplete, :on => :collection
  end

  get 'pages/home'
  get 'pages/contact'
  root :to => 'pages#home'
end
