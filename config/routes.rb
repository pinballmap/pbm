Pbm::Application.routes.draw do
  resources :locations
  devise_for :users
  root :to => "welcome#index"
end
