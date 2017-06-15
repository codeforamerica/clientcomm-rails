Rails.application.routes.draw do
  # For details on the DSL available within this file,
  # see http://guides.rubyonrails.org/routing.html

  # USERS
  devise_for :users

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

  # DELAYED JOB WEB
  authenticated :user do
    match "/delayed_job" => DelayedJobWeb, :anchor => false, :via => [:get, :post]
  end

  # TESTS
  resource :file_preview, only: %i[show] if Rails.env.test? || Rails.env.development?
end
