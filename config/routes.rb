require 'sidekiq/web'

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  resource :messages, only: :create
  post 'messages/delivery_status', to: 'messages#delivery_status', as: :message_delivery_status

  #sidekiq
  mount Sidekiq::Web => "/sidekiq"

  # Defines the root path route ("/")
  # root "articles#index"
end
