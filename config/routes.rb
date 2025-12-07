Rails.application.routes.draw do

  # Invitations
  get ":account_slug/invitations", to: "invitations#index", as: :invitations
  get ":account_slug/invitations/new", to: "invitations#new", as: :new_invitation
  get ":account_slug/invitations/:id", to: "invitations#edit", as: :edit_invitation
  get ":account_slug/invitations/:id/resend", to: "invitations#resend", as: :resend_invitation
  get ":account_slug/invitations/:id/accept", to: "invitations#accept_invitation", as: :accept_invitation
  post ":account_slug/invitations/:id/process", to: "invitations#process_invitation", as: :process_invitation
  post ":account_slug/invitations", to: "invitations#create", as: :create_invitation
  delete ":account_slug/invitations/:id", to: "invitations#destroy", as: :destroy_invitation
  patch ":account_slug/invitations/:id", to: "invitations#update", as: :update_invitation

  # Account Users
  get ":account_slug/members", to: "account_users#index", as: :account_users
  get ":account_slug/members/:id", to: "account_users#edit", as: :edit_account_user
  patch ":account_slug/members/:id", to: "account_users#update", as: :update_account_user
  delete ":account_slug/members/:id", to: "account_users#destroy", as: :destroy_account_user

  # Accounts
  get "accounts", to: "accounts#index", as: :accounts
  get "accounts/new", to: "accounts#new", as: :new_account
  post "accounts", to: "accounts#create", as: :create_account
  get ":account_slug/settings", to: "accounts#edit", as: :account_settings
  get ":account_slug/switch", to: "accounts#switch", as: :switch_account
  patch ":account_slug/update_account", to: "accounts#update", as: :update_account
  delete ":account_slug/destroy_account", to: "accounts#destroy", as: :destroy_account

  # Authentication
  get "signup", to: "registrations#new", as: :new_registration
  post "registration/create", to: "registrations#create", as: :registration
  resource :session, except: %i(new)
  get "login", to: "sessions#new", as: :new_session
  resources :passwords, param: :token

  # User Profile
  get "users/edit", to: "users#edit", as: :edit_user_profile
  patch "users/update_profile", to: "users#update_profile", as: :update_user_profile
  get "users/manage_password", to: "users#manage_password", as: :manage_password
  patch "users/update_password", to: "users#update_password", as: :update_password
  get "users/remove_avatar", to: "users#remove_avatar", as: :remove_user_avatar

  root "pages#home"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
