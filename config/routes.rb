Rails.application.routes.draw do
  devise_for :users, path: "auth"

  get "up" => "rails/health#show", as: :rails_health_check

  resources :users, only: [:index]
  resources :companies do
    member do
      post :import_employees
    end
    resources :employees
  end
  resources :employees, only: [:index, :show, :edit, :update]
  resources :documents, only: [:index] do
    collection do
      post :convert
    end
  end
  resources :conversion_logs, only: [:index]
  resources :payroll_archives, only: [:index]
  resources :period_reports, only: [:index]

  root "dashboard#index"
end
