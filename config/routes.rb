Rails.application.routes.draw do
  apipie

  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  devise_for :users, :controllers => {sessions: 'sessions', registrations: 'registrations'}, path: '/users', path_names: { sign_in: 'login', sign_out: 'logout', sign_up: 'join'}

  namespace :api do
    namespace :v1 do
      resources :location_machine_xrefs, only: [:create, :destroy, :update, :show]
      resources :location_types, only: [:index, :show]
      resources :machine_conditions, only: [:destroy]
      resources :machine_score_xrefs, only: [:create, :show]
      resources :machines, only: [:index, :show, :create]
      resources :operators, only: [:index, :show]

      resources :users, only: [:auth_details] do
        member do
          get  :profile_info
        end
        collection do
          get  :auth_details
          post :signup
        end
      end
      resources :regions, only: [:index, :show] do
        collection do
          get  :closest_by_lat_lon
          get  :does_region_exist
          get  :location_and_machine_counts
          post :suggest
          post :contact
          post :app_comment
        end
      end
      resources :locations, only: [:index, :show, :update] do
        member do
          get :machine_details
          put :confirm
        end
        collection do
          get :closest_by_lat_lon
          get :closest_by_address
          get :autocomplete
          post :suggest
        end
      end

      scope 'region/:region', constraints: lambda { |request| Region.where('lower(name) = ?', request[:region].downcase).any? } do
        resources :events, only: [:index, :show]
        resources :location_machine_xrefs, only: [:index]
        resources :locations, only: [:index, :show]
        resources :machine_score_xrefs, only: [:index, :show]
        resources :operators, only: [:index]
        resources :region_link_xrefs, only: [:index, :show]
        resources :user_submissions, only: [:index, :show]
        resources :zones, only: [:index, :show]
      end
    end
  end

  get '/app' => 'pages#app'
  get '/app/support' => 'pages#app_support'
  get '/privacy' => 'pages#privacy'
  get '/faq' => 'pages#faq'
  get '/store' => 'pages#store'
  get '/donate' => 'pages#donate'

  scope ':region', constraints: lambda { |request| Region.where('lower(name) = ?', request[:region].downcase).any? } do
    get 'app' => redirect('/app')
    get 'app/support' => redirect('/app/support')
    get 'privacy' => redirect('/privacy')
    get 'faq' => redirect('/faq')
    get 'store' => redirect('/store')
    get 'donate' => redirect('/donate')

    resources :events, only: [:index, :show]
    resources :regions, only: [:index, :show]
    resources :location_machine_xrefs, only: [:index], format: 'rss', :as => :lmx_rss
    resources :machine_score_xrefs, only: [:index], format: 'rss', :as => :msx_rss

    resources :pages

    # xml/rss mismatch to support rss-formatted output with $region.xml urls, $region.rss is already expected by mobile devices, and is expected to be formatted without hrefs
    get ':region' + '.xml' => 'location_machine_xrefs#index', format: 'rss'

    get ':region' + '.rss' => 'location_machine_xrefs#index', format: 'xml'
    get ':region' + '_scores.rss' => 'machine_score_xrefs#index', format: 'xml'
    get '/robots.txt', to: 'pages#robots'

    get '/' => 'pages#region', as: 'region_homepage'
    get '/about' => 'pages#about'
    get '/contact' => 'pages#contact'
    get '/contact_sent' => 'pages#contact_sent'
    get '/links' => 'pages#links'
    get '/high_rollers' => 'pages#high_rollers'
    get '/suggest' => 'pages#suggest_new_location'
    get '/submitted_new_location' => 'pages#submitted_new_location'
    get '/flier' => 'pages#flier'

    get 'all_region_data.json', to: 'regions#all_region_data', format: 'json'

    get '*page', to: 'locations#unknown_route'
  end

  resources :locations, only: [:index, :show] do
    collection do
      get :update_desc
      get :update_metadata
      get :autocomplete
    end
    member do
      get :confirm
      get :locations_for_machine
      get :newest_machine_name
      get :render_add_machine
      get :render_desc
      get :render_update_metadata
      get :render_machine_names_for_infowindow
      get :render_last_updated
      get :render_location_detail
      get :render_machines
      get :render_scores
    end
  end

  resources :machines, only: [:index, :show] do
    collection do
      get :autocomplete
    end
  end

  resources :location_machine_xrefs do
    collection do
      get :update_machine_condition
    end
    member do
      get :condition_update_confirmation
      get :create_confirmation
      get :remove_confirmation
      get :render_machine_condition
      get :render_machine_conditions
    end
  end

  resources :machine_score_xrefs
  resources :location_picture_xrefs
  resources :machine_conditions
  resources :suggested_locations, only: [] do
      member do
        post :convert_to_location
      end
  end

  resources :users, only: [:profile] do
    member do
      get :profile
    end
  end

  get 'inspire_profile' => 'pages#inspire_profile'
  get 'pages/home'
  get 'regionless' => 'pages#regionless'
  get 'regionless_location_data' => 'pages#regionless_location_data'
  get 'suggest' => 'pages#suggest_new_location', as: 'regionless_location_suggest'
  get 'submitted_new_location' => 'pages#submitted_new_location', as: 'regionless_submitted_new_location'

  # legacy names for regions
  get '/milwaukee' => redirect('/wisconsin')
  get '/central-indiana' => redirect('/indiana')
  get '/mid-michigan' => redirect('/michigan-mid')
  get '/burlington' => redirect('/vermont')
  get '/apps' => redirect('/app')
  get '/apps/support' => redirect('/app/support')
  get '/profile' => redirect('/inspire_profile')
  get '/twincities' => redirect('/minnesota')
  get '/maryland-north' => redirect('/baltimore')
  get '/portland-maine' => redirect('/maine')

  root to: 'pages#home'
end
