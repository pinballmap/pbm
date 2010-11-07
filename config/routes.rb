Pbm::Application.routes.draw do
  resources :locations, :machines
  devise_for :users
  root :to => "welcome#index"
end
