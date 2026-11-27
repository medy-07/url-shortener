Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    resources :urls, only: :create
  end

  # Keep last: matches any single path segment that looks like a short code.
  get "/:code", to: "redirects#show", as: :short_url, format: false, constraints: { code: /[0-9a-zA-Z_-]+/ }
end
