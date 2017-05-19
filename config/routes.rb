Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  # USERS
  devise_for :users

  # CLIENTS
  root to: "clients#index"
  resources :clients, only: [:index, :new, :create]

  # TWILIO
  post '/incoming/sms', to: 'twilio#incoming_sms'
  post '/incoming/voice', to: 'twilio#incoming_voice'
end
