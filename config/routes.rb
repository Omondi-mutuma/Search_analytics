Rails.application.routes.draw do
  resources :searches, only: [:create]
end
