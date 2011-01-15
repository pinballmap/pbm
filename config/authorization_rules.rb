authorization do
  role :admin do
    has_permission_on [:locations, :machines, :zones, :regions], :to => [:index, :show, :new, :create, :edit, :update, :destroy]
    has_permission_on :rails_admin_history, :to => :list
    has_permission_on :rails_admin_main, :to => [:index, :show, :new, :edit, :create, :update, :destroy, :list, :delete, :get_pages, :show_history]
  end

  role :site_admin do
    includes :admin
  end
end
