Pbm::Application.routes.draw do
  get "pages/home"
  get "pages/contact"

  resources :locations, :machines
  devise_for :users
  root :to => "pages#home"

  resources :locations do
    get :autocomplete_location_name, :on => :collection
  end
end
