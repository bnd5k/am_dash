Rails.application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: :omniauth_callbacks }

  devise_scope :user do 
    get "welcome", to: "devise/sessions#new", as: :welcome
  end

  resources :locations 

  get "loading", to: "dashboard#loading"
  get "status", to: "dashboard#status"

  root to: "dashboard#index"
end
