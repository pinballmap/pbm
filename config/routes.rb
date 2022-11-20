Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  apipie

  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  devise_for :users, :controllers => {sessions: 'sessions', registrations: 'registrations'}, path: '/users', path_names: { sign_in: 'login', sign_out: 'logout', sign_up: 'join'}

  namespace :api do
    namespace :v1 do
      resources :location_types, only: [:index, :show]
      resources :machine_conditions, only: [:destroy]
      resources :machine_score_xrefs, only: [:create, :show]
      resources :machines, only: [:index, :show, :create]
      resources :operators, only: [:index, :show]

      resources :user_submissions, only: [:list_within_range, :location, :total_user_submission_count] do
        collection do
          get :list_within_range
          get :location
          get :total_user_submission_count
          get :top_users
        end
      end

      resources :users, only: [:auth_details, :total_user_count] do
        member do
          post :add_fave_location
          get  :list_fave_locations
          get  :profile_info
          post :remove_fave_location
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
          post :app_comment
        end
      end
      resources :location_machine_xrefs, only: [:create, :destroy, :update, :show] do
        collection do
          get :top_n_machines
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
          get :within_bounding_box
          get :autocomplete
          get :autocomplete_city
          get :top_cities
          get :top_cities_by_machine
          get :type_count
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
  get '.well-known/apple-app-site-association' => 'pages#apple_app_site_association'
  get '.well-known/assetlinks.json' => 'pages#assetlinks', :defaults => { :format => 'json' }

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
    post '/contact_sent' => 'pages#contact_sent'
    get '/links' => 'pages#links'
    get '/high_rollers' => 'pages#high_rollers'
    get '/suggest' => 'pages#suggest_new_location'
    post '/submitted_new_location' => 'pages#submitted_new_location'
    get '/flier' => 'pages#flier'

    get 'all_region_data.json', to: 'regions#all_region_data', format: 'json'

    get '*page', to: 'locations#unknown_route'
  end

  resources :locations, only: [:index, :show] do
    collection do
      get :update_desc
      get :update_metadata
      get :autocomplete
      get :autocomplete_city
    end
    member do
      get :confirm
      get :locations_for_machine
      get :newest_machine_name
      get :render_add_machine
      get :render_desc
      get :render_update_metadata
      get :render_machine_names_for_infowindow
      get :render_machines_count
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

  resources :users, only: [:profile, :fave_locations, :toggle_fave_location] do
    member do
      get :profile, :fave_locations
      post :toggle_fave_location
    end
  end

  get 'inspire_profile' => 'pages#inspire_profile'
  get 'pages/home'
  get 'map' => 'pages#map'
  get 'saved' => 'pages#map', user_faved: true
  get 'map_location_data' => 'pages#map_location_data'
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
  get '/apps/support' => redirect('/app/support')
  get '/profile' => redirect('/inspire_profile')
  get '/twincities' => redirect('/minnesota')
  get '/maryland-north' => redirect('/baltimore')
  get '/portland-maine' => redirect('/maine')
  get '/orlando' => redirect('/florida-central')
  get '/london' => redirect('/uk')
  get '/chico' => redirect('/map')
  get '/michigan-west' => redirect('/map')
  get '/michigan-mid' => redirect('/map')

  root to: 'pages#home'
end
