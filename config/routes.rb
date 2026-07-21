Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  apipie

  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  devise_for :users, :controllers => {sessions: 'sessions', registrations: 'registrations', passwords: 'passwords'}, path: '/users', path_names: { sign_in: 'login', sign_out: 'logout', sign_up: 'join'}

  namespace :api do
    namespace :v1 do
      resources :location_types, only: [:index, :show]
      resources :machine_conditions, only: [:destroy, :update]
      resources :machines, only: [:index, :show]
      resources :machine_groups, only: [:index, :show]
      resources :operators, only: [:index, :show]
      resources :statuses, only: [:index, :show]

      resources :machine_score_xrefs, only: [:destroy, :update, :create, :show] do
        collection do
          get :highest
        end
      end
      resources :user_submissions do
        collection do
          get :list_within_range
          get :location
          get :total_user_submission_count
          get :total_user_submission_count_week
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
          post :update_email
          post :update_password
          post :update_user_flag
          post :add_life_list_machine
          post :remove_life_list_machine
        end
        collection do
          get  :total_user_count
          get  :auth_details
          get  :life_list_info
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
          get :picture_details
          put :confirm
        end
        collection do
          get :geocode_lat_lon
          get :closest_by_lat_lon
          get :closest_by_address
          get :within_bounding_box
          get :autocomplete
          get :autocomplete_city
          get :top_cities
          get :top_cities_by_machine
          get :type_count
          get :countries
          get :top_locations
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
  get '/stats' => 'pages#stats'
  get '/addscore' => 'machine_score_xrefs#new', as: 'add_score'

  scope ':region', constraints: lambda { |request| Region.where('lower(name) = ?', request.params[:region].downcase).any? } do
    get 'app' => redirect('/app')
    get 'app/support' => redirect('/faq')
    get 'privacy' => redirect('/privacy')
    get 'faq' => redirect('/faq')
    get 'store' => redirect('/store')
    get 'donate' => redirect('/donate')
    get 'stats' => redirect('/stats')
    get 'flier' => redirect('/flier')

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
      get :render_lmx_count_row
      get :render_last_updated
      get :render_location_detail
      get :render_machines
      get :render_recent_activity
      get :random_machine
    end
  end

  resources :machines, only: [:index, :show] do
    member do
      get :opdb_img
    end
    collection do
      get :autocomplete
      get :manufacturers
      get :years
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
      get :render_machine_scores
      get :render_life_list
      patch :ic_toggle
    end
  end

  resources :machine_score_xrefs
  resources :user_machine_xrefs, only: [ :create, :destroy ]
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

  resource :api_token, only: [ :show, :create ] do
    member do
      post :regenerate
    end
  end

  resources :api_token_approvals, only: [] do
    member do
      post :approve
      post :deny
      post :revoke
      post :regenerate
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
  get '/search/autocomplete', to: 'search#autocomplete'
  get 'map' => 'maps#map'
  get 'operators', to: redirect('/map')
  get 'operators_autocomplete' => 'maps#operators_autocomplete'
  get 'saved', to: redirect('/map')
  get 'map_location_data' => 'maps#map_location_data'
  post 'map_location_data' => 'maps#map_location_data'
  post 'region_location_load' => 'maps#region_location_load'
  post 'map_location_load' => 'maps#map_location_load'
  post 'get_bounds_load' => 'maps#get_bounds_load'
  post 'nearby_locations_load' => 'maps#nearby_locations_load'
  post 'get_bounds', to: 'maps#get_bounds'
  post 'map_nearby', to: 'maps#map_nearby'
  post 'locations', to: 'locations#index'
  post 'region_init_load', to: 'maps#region_init_load'
  get  'contact' => 'pages#contact', as: 'global_contact'
  post 'contact_sent' => 'pages#contact_sent', as: 'global_contact_sent'
  get 'suggest' => 'pages#suggest_new_location', as: 'map_location_suggest'
  get 'check_place_id' => 'pages#check_place_id', as: 'map_check_place_id'
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

  match '*unmatched', to: 'application#no_route', via: :all, constraints: lambda { |req| req.path.include? 'favicon' }

  root to: 'pages#home'
end
