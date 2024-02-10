Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: 'users/registrations' }
  root 'home#index'
  post '/mypage/new', to: 'mypage#new', as: 'new_mypage'
  post '/mypage/destroy', to: 'mypage#destroy', as: 'destroy_mypage' # 名前を変更
  resources :search, only: [:index, :new, :show]
  resource :mypage, controller: 'mypage', only: [:show, :new, :destroy]
end
