# frozen_string_literal: true

module Api
  module V1
    class ApiController < ActionController::API
      include ActionController::HttpAuthentication::Basic::ControllerMethods

      before_action :authorize

      def url_options
        # API runs on a separate subdomain in production, so make sure the default
        # subdomain is always `www` for route helpers
        return super.merge(subdomain: 'www') if ENV['HEROKU_ENV'] == 'production'

        super
      end

      private

      def authorize
        render json: { type: :authentication_error }, status: 401 unless api_key_valid?
      end

      def api_key_valid?
        # We only have one API customer so hard-code check their API key
        authenticate_with_http_basic { |username, _| username == '***REMOVED***' }
      end
    end
  end
end
