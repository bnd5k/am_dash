Rails.application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: :omniauth_callbacks }

  devise_scope :user do 
    get 'welcome', to: "devise/sessions#new", as: :welcome
  end

  resources :locations 

  root to: "dashboard#index"
end
