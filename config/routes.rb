Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  apipie

  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  devise_for :users, :controllers => {sessions: 'sessions', registrations: 'registrations', passwords: 'passwords'}, path: '/users', path_names: { sign_in: 'login', sign_out: 'logout', sign_up: 'join'}

  namespace :api do
    namespace :v1 do
      resources :location_types, only: [:index, :show]
      resources :machine_conditions, only: [:destroy, :update]
      resources :machine_score_xrefs, only: [:create, :show]
      resources :machines, only: [:index, :show]
      resources :machine_groups, only: [:index, :show]
      resources :operators, only: [:index, :show]
      resources :statuses, only: [:index, :show]

      resources :user_submissions do
        collection do
          get :list_within_range
          get :location
          get :total_user_submission_count
          get :top_users
          get :delete_location
        end
      end

      resources :users do
        member do
          post :add_fave_location
          get  :list_fave_locations
          get  :profile_info
          post :remove_fave_location
          get  :render_user_flag
          post :update_user_flag
        end
        collection do
          get :total_user_count
          get  :auth_details
          post :signup
          post :forgot_password
          post :resend_confirmation
        end
      end
      resources :regions, only: [:index, :show] do
        collection do
          get  :closest_by_lat_lon
          get  :does_region_exist
          get  :location_and_machine_counts
          post :suggest
          post :contact
        end
      end
      resources :location_machine_xrefs, only: [:create, :destroy, :update, :show] do
        put :ic_toggle
        collection do
          get :top_n_machines
          get :most_recent_by_lat_lon
        end
      end
      resources :location_picture_xrefs, only: [:create, :destroy, :show]
      resources :locations, only: [:index, :show, :update] do
        member do
          get :machine_details
          put :confirm
        end
        collection do
          get :closest_by_lat_lon
          get :closest_by_address
          get :within_bounding_box
          get :autocomplete
          get :autocomplete_city
          get :top_cities
          get :top_cities_by_machine
          get :type_count
          get :countries
          post :suggest
        end
      end

      scope 'region/:region', constraints: lambda { |request| Region.where('lower(name) = ?', request.params[:region].downcase).any? } do
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
  get '/privacy' => 'pages#privacy'
  get '/faq' => 'pages#faq'
  get '/store' => 'pages#store'
  get '/donate' => 'pages#donate'
  get '.well-known/apple-app-site-association' => 'pages#apple_app_site_association'
  get '/apple-app-site-association' => 'pages#apple_app_site_association'
  get '/robots.txt' => 'pages#robots'
  get '/activity' => 'pages#recent_activity'
  post '/activity' => 'pages#recent_activity'

  scope ':region', constraints: lambda { |request| Region.where('lower(name) = ?', request.params[:region].downcase).any? } do
    get 'app' => redirect('/app')
    get 'app/support' => redirect('/faq')
    get 'privacy' => redirect('/privacy')
    get 'faq' => redirect('/faq')
    get 'store' => redirect('/store')
    get 'donate' => redirect('/donate')

    resources :events, only: [:index, :show]
    resources :regions, only: [:index, :show]
    resources :location_machine_xrefs, only: [:index], format: 'rss', :as => :lmx_rss
    get '/location_machine_xrefs/machine_id(/:machine_id)', to: 'location_machine_xrefs#index', format: 'rss', :as => :single_lmx_rss_region
    resources :machine_score_xrefs, only: [:index], format: 'rss', :as => :msx_rss

    resources :pages

    get ':region' + '.rss' => 'location_machine_xrefs#index', format: 'xml'
    get ':region' + '_scores.rss' => 'machine_score_xrefs#index', format: 'xml'

    get '/' => 'maps#region', as: 'region_homepage'
    get '/about' => 'pages#about'
    get '/contact' => 'pages#contact'
    post '/contact_sent' => 'pages#contact_sent'
    get '/links' => 'pages#links'
    get '/high_rollers' => 'pages#high_rollers'
    get '/suggest' => 'pages#suggest_new_location'
    post '/submitted_new_location' => 'pages#submitted_new_location'
    get '/activity' => 'pages#recent_activity', as: 'region_activity'
    post '/activity' => 'pages#recent_activity', as: 'region_post_activity'

    get '*page', to: 'locations#unknown_route'
  end

  resources :locations, only: [:index, :show] do
    collection do
      patch :update_metadata
      get :autocomplete
      get :autocomplete_city
    end
    member do
      get :confirm
      get :render_add_machine
      get :render_update_metadata
      get :render_machines_count
      get :render_last_updated
      get :render_location_detail
      get :render_machines
      get :render_scores
      get :render_former_machines
      get :render_recent_activity
    end
  end

  resources :machines, only: [:index, :show] do
    collection do
      get :autocomplete
    end
  end

  resources :operators, only: [:show] do
    collection do
      get :autocomplete
    end
  end

  get '/location_machine_xrefs/machine_id(/:machine_id)', to: 'location_machine_xrefs#index', format: 'rss', :as => :single_lmx_rss_global

  resources :location_machine_xrefs do
    collection do
      patch :update_machine_condition
    end
    member do
      get :render_machine_tools
      get :render_machine_conditions
      patch :ic_toggle
    end
  end

  resources :machine_score_xrefs
  resources :location_picture_xrefs do
    member do
      get :form
    end
  end
  resources :machine_conditions
  resources :suggested_locations, only: [] do
    member do
      post :convert_to_location
    end
  end

  resources :users do
    member do
      get :profile, constraints: { id: /[^\/]+/ }
      post :toggle_fave_location
      post :update_user_flag
      get :render_user_flag
    end
  end

  get 'user_submissions/list_within_range' => 'user_submissions#list_within_range'

  get 'inspire_profile' => 'pages#inspire_profile'
  get 'pages/home'
  get 'map' => 'maps#map'
  get 'operators' => 'maps#operators'
  get 'operator_location_data' => 'maps#operator_location_data'
  get 'saved' => 'maps#map', user_faved: true
  get 'map_location_data' => 'maps#map_location_data'
  post 'map_bounds', to: 'maps#get_bounds'
  post 'map_nearby', to: 'maps#map_nearby'
  post 'region_init_load', to: 'maps#region_init_load'
  get 'suggest' => 'pages#suggest_new_location', as: 'map_location_suggest'
  post 'submitted_new_location' => 'pages#submitted_new_location', as: 'map_submitted_new_location'
  get 'flier' => 'pages#flier', as: 'map_flier'

  # legacy names for regions
  get '/milwaukee' => redirect('/wisconsin')
  get '/regionless' => redirect('/map')
  get '/central-indiana' => redirect('/indiana')
  get '/mid-michigan' => redirect('/map')
  get '/burlington' => redirect('/vermont')
  get '/apps' => redirect('/app')
  get '/apps/support' => redirect('/faq')
  get '/app/support' => redirect('/faq')
  get '/profile' => redirect('/inspire_profile')
  get '/twincities' => redirect('/minnesota')
  get '/maryland-north' => redirect('/baltimore')
  get '/portland-maine' => redirect('/maine')
  get '/orlando' => redirect('/florida-central')
  get '/london' => redirect('/uk')
  get '/chico' => redirect('/map')
  get '/michigan-west' => redirect('/michigan-sw')
  get '/michigan-mid' => redirect('/michigan-north')
  get '/albuquerque' => redirect('/new-mexico')
  get '/roanoke' => redirect('/map')
  get '/redding' => redirect('/map')
  get '/bakersfield' => redirect('/map')
  get '/springfield' => redirect('/map')
  get '/charlottesville' => redirect('/map')
  get '/poohbear' => redirect('/')

  root to: 'pages#home'
end
