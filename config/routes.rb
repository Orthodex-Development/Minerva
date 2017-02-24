Rails.application.routes.draw do
  namespace :api, defaults: { format: :json } do
    post '/tokenize', to: 'tokenizer#tokenize'
  end
end
