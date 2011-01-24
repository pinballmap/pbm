Pbm::Application.routes.draw do
  scope ':region', :constraints => { :region => /portland|chicago/i } do
    resources :pages
    resources :regions
    resources :machines
    resources :locations do
      collection do
        get :remove_machine
        get :add_machine
        get :update_machine_condition
        get :add_high_score
      end
    end

    match '/' => "pages#region"
  end

  devise_for :users

  resources :locations, :machines do
    get :autocomplete, :on => :collection
  end

  get 'pages/home'
  get 'pages/contact'
  root :to => 'pages#home'
end
