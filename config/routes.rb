Rails.application.routes.draw do

  # For details on the DSL available within this file,
  # see http://guides.rubyonrails.org/routing.html

  # USERS / DEVISE
  devise_for :users, controllers: {
    registrations: 'users/registrations',
    invitations: 'users/invitations',
    sessions: 'users/sessions'
  }

  # CLIENTS and MESSAGES
  root to: "clients#index"
  resources :clients, only: [:index, :new, :create, :edit, :update] do
    resources :messages, only: [:index, :new]
    get 'scheduled_messages/index'
    get 'messages/download', to: 'messages#download'
    put 'archive', to: 'clients#archive'
  end

  resources :messages, only: [:create, :edit, :update] do
    scope module: :messages do
      resource :read, only: :create
    end
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

  match '/404', to: 'errors#not_found', via: :all
  match '/500', to: 'errors#internal_server_error', via: :all

  # TESTS
  resource :file_preview, only: %i[show] if Rails.env.test? || Rails.env.development?

  # This should always be last
  get '*url' => 'errors#not_found'
end
