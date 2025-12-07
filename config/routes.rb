Rails.application.routes.draw do

  # Admin > Commerce > Subscriptions
  get "admin/commerce/subscriptions", to: "admin/commerce/subscriptions#index", as: :admin_subscriptions
  get "admin/commerce/subscriptions/:id", to: "admin/commerce/subscriptions#show", as: :admin_subscription
  patch "admin/commerce/subscriptions/:id/cancel", to: "admin/commerce/subscriptions#cancel", as: :admin_cancel_subscription

  # Admin > Commerce > Payments
  get "admin/commerce/payments", to: "admin/commerce/payments#index", as: :admin_payments
  get "admin/commerce/payments/:id", to: "admin/commerce/payments#show", as: :admin_payment
  delete "admin/commerce/payments/:id", to: "admin/commerce/payments#destroy", as: :admin_destroy_payment

  # Admin > Commerce > Purchases
  get "admin/commerce/purchases", to: "admin/commerce/purchases#index", as: :admin_purchases
  get "admin/commerce/purchases/:id", to: "admin/commerce/purchases#show", as: :admin_purchase
  delete "admin/commerce/purchases/:id", to: "admin/commerce/purchases#destroy", as: :admin_destroy_purchase

  # Admin > Commerce > Benefits
  get "admin/commerce/benefits", to: "admin/commerce/benefits#index", as: :admin_benefits
  get "admin/commerce/benefits/new", to: "admin/commerce/benefits#new", as: :admin_new_benefit
  post "admin/commerce/benefits", to: "admin/commerce/benefits#create", as: :admin_create_benefit
  get "admin/commerce/benefits/:id", to: "admin/commerce/benefits#edit", as: :admin_edit_benefit
  patch "admin/commerce/benefits/:id", to: "admin/commerce/benefits#update", as: :admin_update_benefit
  delete "admin/commerce/benefits/:id", to: "admin/commerce/benefits#destroy", as: :admin_destroy_benefit

  # Admin > Commerce > Plans > Benefits
  get "admin/commerce/plans/:plan_id/benefits/new", to: "admin/commerce/plan_benefits#new", as: :admin_new_plan_benefit
  get "admin/commerce/plans/:plan_id/benefits/render_assign_benefit_select", to: "admin/commerce/plan_benefits#render_assign_benefit_select", as: :admin_render_assign_benefit_select
  post "admin/commerce/plans/:plan_id/benefits", to: "admin/commerce/plan_benefits#create", as: :admin_create_plan_benefit
  get "admin/commerce/plan_benefits/:id/edit_benefit", to: "admin/commerce/plan_benefits#edit_benefit", as: :admin_edit_benefit_on_plan
  patch "admin/commerce/plan_benefits/:id/update_benefit", to: "admin/commerce/plan_benefits#update_benefit", as: :admin_update_benefit_on_plan
  patch "admin/commerce/plan_benefits/:id/reorder", to: "admin/commerce/plan_benefits#reorder", as: :admin_reorder_plan_benefit
  delete "admin/commerce/plan_benefits/:id/remove", to: "admin/commerce/plan_benefits#destroy", as: :admin_destroy_plan_benefit
  delete "admin/commerce/plan_benefits/:id/delete_benefit", to: "admin/commerce/plan_benefits#delete_benefit", as: :admin_delete_benefit_on_plan

  # Admin > Commerce > Plans
  get "admin/commerce/plans", to: "admin/commerce/plans#index", as: :admin_plans
  get "admin/commerce/plans/new", to: "admin/commerce/plans#new", as: :admin_new_plan
  get "admin/commerce/plans/:id/edit", to: "admin/commerce/plans#edit", as: :admin_edit_plan
  post "admin/commerce/plans", to: "admin/commerce/plans#create", as: :admin_create_plan
  patch "admin/commerce/plans/:id", to: "admin/commerce/plans#update", as: :admin_update_plan
  delete "admin/commerce/plans/:id", to: "admin/commerce/plans#destroy", as: :admin_destroy_plan
  patch "admin/commerce/plans/:id/reorder", to: "admin/commerce/plans#reorder", as: :admin_reorder_plan

  # Admin > Commerce > Products > Prices
  get "admin/commerce/prices", to: "admin/commerce/prices#index", as: :admin_prices
  get "admin/commerce/products/:slug/prices/new", to: "admin/commerce/prices#new", as: :admin_new_price
  post "admin/commerce/products/:slug/prices", to: "admin/commerce/prices#create", as: :admin_create_price
  get "admin/commerce/products/:slug/prices/:id/edit", to: "admin/commerce/prices#edit", as: :admin_edit_price
  patch "admin/commerce/products/:slug/prices/:id", to: "admin/commerce/prices#update", as: :admin_update_price
  delete "admin/commerce/products/:slug/prices/:id", to: "admin/commerce/prices#destroy", as: :admin_destroy_price

  # Admin > Commerce > Products
  get "admin/commerce", to: "admin/commerce/products#commerce_root", as: :admin_commerce
  get "admin/commerce/products", to: "admin/commerce/products#index", as: :admin_products
  get "admin/commerce/products/new", to: "admin/commerce/products#new", as: :admin_new_product
  get "admin/commerce/products/:slug", to: "admin/commerce/products#edit", as: :admin_edit_product
  post "admin/commerce/products", to: "admin/commerce/products#create", as: :admin_create_product
  patch "admin/commerce/products/:slug", to: "admin/commerce/products#update", as: :admin_update_product
  delete "admin/commerce/products/:slug", to: "admin/commerce/products#destroy", as: :admin_destroy_product
  get "admin/commerce/products/:slug/image", to: "admin/commerce/products#remove_image", as: :admin_remove_product_image

  # Stripe Webhooks
  post "/stripe/webhook", to: "commerce/webhooks#stripe", as: :stripe_webhook

  # User-facing Dunning
  get ":account_slug/payments/:id/resolve_payment", to: "commerce/dunning#resolve_payment", as: :resolve_payment
  get ":account_slug/payments/:id/resolve_payment/new_method", to: "commerce/dunning#resolve_with_new_method", as: :resolve_with_new_method
  get ":account_slug/payments/:id/resolve_payment/current_method", to: "commerce/dunning#resolve_with_current_method", as: :resolve_with_current_method
  post ":account_slug/payments/:id/create_setup_intent_for_resolve_payment", to: "commerce/dunning#create_setup_intent_for_resolve_payment", as: :create_setup_intent_for_resolve_payment
  post ":account_slug/payments/:id/retry_payment", to: "commerce/dunning#retry_payment", as: :retry_payment

  # User-facing Purchases
  get ":account_slug/billing/purchases", to: "commerce/purchases#index", as: :purchases
  get ":account_slug/billing/purchases/:id", to: "commerce/purchases#show", as: :purchase

  # User-facing Subscription Management
  get ":account_slug/billing/subscription/:id", to: "commerce/subscriptions#show", as: :subscription
  get ":account_slug/billing/subscription/:id/cancel", to: "commerce/subscriptions#cancel", as: :cancel_subscription
  post ":account_slug/billing/subscription/:id/process_cancellation", to: "commerce/subscriptions#process_cancellation", as: :process_cancellation
  get ":account_slug/billing/subscription/:id/resume", to: "commerce/subscriptions#resume", as: :resume_subscription
  patch ":account_slug/billing/subscription/:id/update", to: "commerce/subscriptions#update", as: :update_subscription
  get ":account_slug/billing/subscription/:id/edit_payment_method", to: "commerce/subscriptions#edit_payment_method", as: :edit_payment_method
  patch ":account_slug/billing/subscription/:id/update_payment_method", to: "commerce/subscriptions#update_payment_method", as: :update_payment_method_subscription

  # User-facing Billing Overview & Payment Methods
  get ":account_slug/billing", to: "commerce/billing#overview", as: :billing_overview
  get ":account_slug/billing/payment_methods", to: "commerce/payment_methods#index", as: :payment_methods
  get ":account_slug/billing/payment_methods/new", to: "commerce/payment_methods#new", as: :new_payment_method
  post ":account_slug/billing/payment_methods", to: "commerce/payment_methods#create", as: :create_payment_method
  delete ":account_slug/billing/payment_methods/:id", to: "commerce/payment_methods#destroy", as: :destroy_payment_method
  patch ":account_slug/billing/payment_methods/:id/make_default", to: "commerce/payment_methods#make_default", as: :make_default_payment_method
  post ":account_slug/billing/payment_methods/create_setup_intent", to: "commerce/payment_methods#create_setup_intent", as: :create_setup_intent
  get ":account_slug/billing/payment_methods/process_create_payment_method", to: "commerce/payment_methods#process_create_payment_method", as: :process_create_payment_method
  get ":account_slug/billing/payments", to: "commerce/payments#index", as: :payments
  get ":account_slug/billing/payments/:id", to: "commerce/payments#show", as: :payment

  # User-facing Plans
  get "/plans", to: "commerce/plans#index", as: :plans
  get ":account_slug/billing/subscription/:id/edit", to: "commerce/subscriptions#edit_plan", as: :edit_plan

  # User-facing Products
  get "/products", to: "commerce/products#index", as: :products
  get "/products/:slug", to: "commerce/products#show", as: :product

  # Checkout
  get "/checkout", to: "commerce/checkout#checkout", as: :checkout
  post "/checkout/register", to: "commerce/checkout#register_at_checkout", as: :register_at_checkout
  post "/checkout/login", to: "commerce/checkout#login_at_checkout", as: :login_at_checkout
  get "/checkout/login", to: "commerce/checkout#switch_to_login", as: :switch_to_login_at_checkout
  get "/checkout/register", to: "commerce/checkout#switch_to_register", as: :switch_to_register_at_checkout
  get "/checkout/:product/new_payment_method", to: "commerce/checkout#switch_to_new_payment_method", as: :switch_to_new_payment_method
  get "/checkout/switch_to_existing_payment_method", to: "commerce/checkout#switch_to_existing_payment_method", as: :switch_to_existing_payment_method
  post "/checkout/:product/create_payment_intent", to: "commerce/checkout#create_payment_intent", as: :create_payment_intent
  get "/checkout/process", to: "commerce/checkout#process_checkout", as: :process_checkout
  get "/checkout/success", to: "commerce/checkout#checkout_success", as: :checkout_success
  get "/checkout/validate_coupon", to: "commerce/checkout#validate_coupon", as: :validate_coupon

  # Admin > Accounts
  get "admin/accounts", to: "admin/accounts#index", as: :admin_accounts
  get "admin/accounts/:id", to: "admin/accounts#show", as: :admin_account

  # Admin > Users
  get "admin/users", to: "admin/users#index", as: :admin_users
  get "admin/users/:id", to: "admin/users#show", as: :admin_user
  post "admin/impersonate/:id", to: "admin/users#impersonate_user", as: :impersonate_user
  delete "admin/impersonate/:id", to: "admin/users#stop_impersonating_user", as: :stop_impersonating_user

  # Admin
  get "admin", to: "admin/dashboard#dashboard", as: :admin_dashboard

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
