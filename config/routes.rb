Rails.application.routes.draw do
  require 'sidekiq/web'
  
  namespace :api, defaults: { format: :json } do
    post '/tokenize', to: 'tokenizer#tokenize'
  end

  mount Sidekiq::Web => '/sidekiq'
end
