regions = 'portland|chicago|toronto'

if Region.table_exists? && Region.all.size > 0
  regions = Region.all.each.map { |r| r.name }.join('|')
end

Pbm::Application.routes.draw do
  apipie

  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'

  namespace :api do
    namespace :v1 do
      resources :machines, only: [:index, :show, :create]
      resources :location_types, only: [:index, :show]
      resources :location_machine_xrefs, only: [:create, :destroy, :update]
      resources :machine_score_xrefs, only: [:create, :show]
      resources :machine_conditions, only: [:destroy]

      resources :regions, only: [:index, :show] do
        collection do
          get  :closest_by_lat_lon
          post :suggest
          post :contact
          post :app_comment
        end
      end
      resources :locations, only: [:update] do
        member do
          get :machine_details
        end
        collection do
          get :closest_by_lat_lon
          post :suggest
        end
      end

      scope 'region/:region', constraints: { region: /#{regions}|!admin/i } do
        resources :machine_score_xrefs, only: [:index]
        resources :location_machine_xrefs, only: [:index]
        resources :events, only: [:index, :show]
        resources :locations, only: [:index, :show]
        resources :region_link_xrefs, only: [:index, :show]
        resources :zones, only: [:index, :show]
        resources :user_submissions, only: [:index, :show]
      end
    end
  end

  get '/apps' => 'pages#apps'
  get '/apps/support' => 'pages#app_support'
  get '/privacy' => 'pages#privacy'
  get '/store' => 'pages#store'

  scope ':region', constraints: { region: /#{regions}|!admin/i } do
    get 'apps' => redirect('/apps')
    get 'apps/support' => redirect('/apps/support')

    resources :events, only: [:index, :show]
    resources :regions, only: [:index, :show]

    resources :machines, only: [:index, :show] do
      collection do
        get :autocomplete
      end
    end

    resources :pages
    resources :machine_score_xrefs

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
        get :render_machines
        get :render_scores
        get :render_last_updated
      end
    end

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

    get 'iphone.html', to: 'locations#mobile'
    get 'mobile', to: 'locations#mobile'

    get 'all_region_data.json', to: 'regions#all_region_data', format: 'json'

    get '*page', to: 'locations#unknown_route'
  end

  resources :location_picture_xrefs
  resources :machine_conditions

  devise_for :users

  get 'iphone.html', to: 'locations#mobile'
  get '4sq_export.xml' => 'regions#four_square_export', format: 'xml'
  get 'pages/home'

  # legacy names for regions
  get '/milwaukee' => redirect('/wisconsin')

  root to: 'pages#home'
end
