Rails.application.routes.draw do
  root 'index#index'
  get '/results/:id' => 'index#show', as: :results

  require 'sidekiq/web'

  namespace :api, defaults: { format: :json } do
    post '/tokenize', to: 'tokenizer#tokenize'
  end

  mount Sidekiq::Web => '/sidekiq'
end
