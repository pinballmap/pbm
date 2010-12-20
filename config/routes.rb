Pbm::Application.routes.draw do
  get 'pages/home'
  get 'pages/contact'

  resources :machines

  resources :locations do
    get :autocomplete, :on => :collection
  end

  devise_for :users
  root :to => 'pages#home'
end
