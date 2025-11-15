Rails.application.routes.draw do
  get "transactions/index"
  get "transactions/show"
  resource :session
  resources :passwords, param: :token

  resources :emails, only: [:index, :show], path: "email"
  resources :transactions, only: [:index, :show]

  # We'll allow only `google` as the provider for now
  scope :oauth, constraints: { provider: /google/ } do
    get "/:provider/start",    to: "email_provider_oauths#start",    as: :oauth_start
    get "/:provider/callback", to: "email_provider_oauths#callback", as: :oauth_callback
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "transactions#index"
end
