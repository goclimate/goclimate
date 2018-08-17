Rails.application.routes.draw do

  resources :invoices
  resources :lifestyle_choices
  resources :projects
  resources :stripe_events
  get 'dashboard/index'

  devise_scope :user do
    get 'users/edit/payment', to: 'users/registrations#payment', as: 'payment'
    get 'users/edit/threedsecure', to: 'users/registrations#threedsecure', as: 'threedsecure'
    get 'users/sign_up_2', to: 'users/registrations#sign_up_2', as: 'sign_up_2'
  end
  devise_for :users, controllers: {
  	sessions: 'users/sessions',
  	registrations: 'users/registrations'
  }
  resources :users, :only => [:show]

  get '/users' => 'dashboard#index', as: :user_root
  get 'about', to: 'welcome#about'
  get 'contact', to: 'welcome#contact'
  get 'faq', to: 'welcome#faq'
  get 'friendlyguide', to: 'welcome#friendlyguide'
  get 'press', to: 'welcome#press'
  get '100_percent_transparency', to: 'welcome#transparency'
  get 'our_projects', to: 'welcome#our_projects'
  get 'companies', to: 'welcome#companies'
  get 'klimatkompensera', to: 'welcome#klimatkompensera'
  get 'admin', to: 'admin#index'

  resources :subscriptions

  get '/blog' => redirect("https://www.goclimateneutral.org/blog/")

  root 'welcome#index'
end
