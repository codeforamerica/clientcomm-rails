Rails.application.routes.draw do
  # For details on the DSL available within this file,
  # see http://guides.rubyonrails.org/routing.html

  # USERS / DEVISE
  devise_for :users, controllers: {
    registrations: 'users/registrations',
    sessions: 'users/sessions'
  }

  # CLIENTS
  root to: "clients#index"
  resources :clients, only: [:index, :new, :create]

  # MESSAGES
  resources :clients do
    resources :messages, only: [:index]
  end
  resources :messages, only: [:create] do
    patch :read
  end

  # TWILIO
  post '/incoming/sms', to: 'twilio#incoming_sms'
  post '/incoming/voice', to: 'twilio#incoming_voice'
  post '/incoming/sms/status', to: 'twilio#incoming_sms_status'

  # WEBSOCKETS
  mount ActionCable.server => '/cable'

  # TESTS
  resource :file_preview, only: %i[show] if Rails.env.test? || Rails.env.development?
end
