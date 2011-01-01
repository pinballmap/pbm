Pbm::Application.routes.draw do
  get 'pages/home'
  get 'pages/contact'

  get 'locations/add_machine'
  get 'locations/remove_machine'

  resources :locations, :machines do
    get :autocomplete, :on => :collection
  end

  devise_for :users
  root :to => 'pages#home'
end
