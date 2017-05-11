require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)


module ClimateNeutralLife
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Where the I18n library should search for translation files
    I18n.load_path += Dir[Rails.root.join('locale', '*.{rb,yml}')]
     
    # Whitelist locales available for the application
    I18n.available_locales = [:en, :sv]
    
    I18n.default_locale = :sv
    
  end
end