Rails.application.routes.draw do
  mount JasmineRails::Engine => '/specs' if defined?(JasmineRails)
  # For details on the DSL available within this file,
  # see http://guides.rubyonrails.org/routing.html

  # ACTIVEADMIN ROUTES
  ActiveAdmin.routes(self)

  # USERS / DEVISE
  devise_for :users, controllers: {
    registrations: 'users/registrations',
    sessions: 'users/sessions',
    passwords: 'users/passwords'
  }

  # CLIENTS and MESSAGES
  devise_scope :user do
    authenticated :user do
      root to: 'clients#index'
    end

    unauthenticated do
      root to: 'users/sessions#new'
    end
  end

  resources :tracking_events, only: [:create]

  resources :clients, only: [:index, :new, :create, :edit, :update] do
    scope module: :clients do
      resource :archive, only: :create
    end
  end

  resources :templates, only: [:index, :new, :create, :edit, :update, :destroy]

  resources :messages, only: [:create, :edit, :update, :destroy] do
    scope module: :messages do
      resource :read, only: :create
    end
  end

  # PUT reporting_relationships_path(rr) => /reporting_relationship/:id
  # GET reporting_relationships_path(rr) => /conversations/:id

  resources :mass_messages, only: [:new, :create]
  resources :reporting_relationships, only: [:create, :update, :show], path: 'conversations' do
    get 'scheduled_messages/index'
    get 'messages/download', to: 'messages#download'
    scope module: :reporting_relationships do
      resource :welcome, only: :new
    end
  end

  resources :help, only: [:index]

  # TWILIO
  post '/incoming/sms', to: 'twilio#incoming_sms'
  post '/incoming/voice', to: 'twilio#incoming_voice'
  post '/incoming/sms/status', to: 'twilio#incoming_sms_status'

  # WEBSOCKETS
  mount ActionCable.server => '/cable'

  # DELAYED JOB WEB
  # disable web because off XSS vuln
  # authenticated :user do
  #   match '/delayed_job' => DelayedJobWeb, :anchor => false, :via => [:get, :post]
  # end

  match '/404', to: 'errors#not_found', via: :all
  match '/500', to: 'errors#internal_server_error', via: :all

  # TESTS
  resource :file_preview, only: %i[show] if Rails.env.test? || Rails.env.development?

  # This should always be last
  get '*url' => 'errors#not_found'
end
