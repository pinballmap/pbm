Pbm::Application.routes.draw do
  get 'pages/home'
  get 'pages/contact'

  resources :locations, :machines do
    get :autocomplete, :on => :collection
  end

  devise_for :users
  root :to => 'pages#home'
end
