Pbm::Application.routes.draw do
  get 'pages/home'
  get 'pages/contact'

  resources :locations, :machines do
    get :autocomplete, :on => :collection
  end

  devise_for :users
  root :to => 'pages#home'

  scope ':region' do
    resource :pages
    resource :locations do
      get :index
      get :remove_machine
      get :add_machine
      get :update_machine_condition
      get :add_high_score
    end

    match '/' => "pages#region"
  end

end
