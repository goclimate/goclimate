# frozen_string_literal: true

Rails.application.routes.draw do
  # Handle legacy locale subdomains. Doing this in Cloudflare requires a paid
  # account for the extra page rules which we currently want to avoid.
  match '(*path)', to: redirect { |_, request| "//www.goclimateneutral.org/se#{request.fullpath}" },
                   via: [:get, :post], constraints: { host: 'sv.goclimateneutral.org' }
  match '(*path)', to: redirect { |_, request| "//www.goclimateneutral.org/de#{request.fullpath}" },
                   via: [:get, :post], constraints: { host: 'de.goclimateneutral.org' }
  match '(*path)', to: redirect { |_, request| "//www.goclimateneutral.org/us#{request.fullpath}" },
                   via: [:get, :post], constraints: { host: 'en.goclimateneutral.org' }

  # API. Available on subdomain `api.` in production and under path `/api` in other environments.
  api = proc do
    namespace 'api', path: '', defaults: { subdomain: ENV['HEROKU_ENV'] == 'production' ? 'api' : false } do
      namespace 'v1', defaults: { format: :json }, constraints: { format: :json } do
        resource :flight_footprint, only: [:show]
      end

      resource :documentations, only: [:show], path: 'docs'
      resources :api_keys, only: [:new, :create], path_names: { new: '' }
    end

    # Other routes should not match for the api subdomain, so catch everything
    # else and return not found. This only makes a difference in production
    # where the subdomain is actually used.
    match '/', to: 'errors#not_found', via: :all
    match '*path', to: 'errors#not_found', via: :all
  end
  ENV['HEROKU_ENV'] == 'production' ? constraints(subdomain: /api|api-temporary/, &api) : scope('/api', &api)

  # Public site
  scope '(:region)', region: Regexp.new(Region.all.map(&:slug).compact.join('|')) do
    root 'welcome#index'

    # Devise routes for sessions, registrations & payment
    devise_for :users, controllers: {
      registrations: 'users/registrations'
    }
    namespace :users, as: 'user' do
      devise_scope :user do
        post 'verify', to: 'registrations#verify', as: 'registration_verify'
      end

      resource :subscription, only: [:show, :update]
      resources :receipts, only: [:index, :show], param: :card_charge_id
    end

    # Content pages
    get 'about', to: 'welcome#about'
    get 'contact', to: 'welcome#contact'
    get 'faq', to: 'welcome#faq'
    get 'press', to: 'welcome#press'
    get '100_percent_transparency', to: 'welcome#transparency', as: 'transparency'
    get 'our_projects', to: 'welcome#our_projects'
    get 'privacy_policy', to: 'welcome#privacy_policy'

    get 'business', to: 'welcome#business'
    namespace :business do
      resources :climate_reports, only: [:show, :new, :create], param: :key do
        member do
          resource :climate_report_invoice, only: [:create], path: 'invoice' do
            get 'thank_you'
          end
        end
      end
    end

    # Business page with post from employee offsetting form
    resource :business, only: [:create]

    # Partners
    get 'partners/bokanerja'
    get 'partners/inshapetravel'
    get 'partners/flygcity'

    # Flight one time offsets
    resources :flight_offsets, only: [:new, :create], param: :key do
      member do
        get 'thank_you'
        scope format: true, constraints: { format: :pdf } do
          resource :flight_offset_certificates, only: [:show], path: :certificate
          resource :flight_offset_receipts, only: [:show], path: :receipt
        end
      end
    end

    # Dashboard
    get 'dashboard', to: 'dashboard#index'

    # User profiles
    resources :users, only: [:show], constraints: { id: /\d+/ }

    # Gift cards
    resources :gift_cards, only: [:index, :new, :create] do
      collection do
        get 'thank_you'

        scope format: true, constraints: { format: :pdf } do
          resources :gift_card_certificates, only: [:show], path: :certificates, param: :key do
            get 'example', on: :collection
          end
        end
      end
      member do
        scope format: true, constraints: { format: :pdf } do
          resource :gift_card_receipts, only: [:show], path: :receipt, param: :key
        end
      end
    end

    # Redirects for old routes. To avoid broken links on the internet, don't remove these.
    defaults region: nil do
      get 'klimatkompensera', to: redirect('%{region}/'), as: nil
      get 'friendlyguide', to: redirect('%{region}/'), as: nil
      get 'gift_cards/example', to: redirect(path: '%{region}/gift_cards/certificates/example.pdf'), as: nil
      get 'gift_cards/download', to: redirect('%{region}/gift_cards/certificates/%{key}.pdf'), as: nil
      get 'dashboard/index', to: redirect('%{region}/dashboard'), as: nil
      get '/users', to: redirect('%{region}/dashboard'), as: nil
      get '/users/edit/payment', to: redirect('%{region}/users/subscription'), as: nil
      get 'companies', to: redirect('%{region}/business'), as: nil
      get 'business_beta', to: redirect('%{region}/business'), as: nil
    end
  end

  # Admin
  namespace :admin do
    root to: 'dashboard#index'
    resources :api_keys
    resources :invoices
    resources :lifestyle_choices
    resources :projects
    resources :climate_report_invoices, only: [:index, :show, :edit, :update]
    resources :climate_reports, only: [:index]
    resource :invoice_certificates, only: [:show] do
      get 'send_email', on: :collection
    end
  end

  resource :impact_statistics, only: [:show], format: true, constraints: { format: :csv }

  # Errors
  match '/404', to: 'errors#not_found', via: :all
  match '/422', to: 'errors#unprocessable_entity', via: :all
  match '/500', to: 'errors#internal_server_error', via: :all

  # Vanity URL redirects
  get '/blog', to: redirect('https://www.goclimateneutral.org/blog/'), as: nil
end
