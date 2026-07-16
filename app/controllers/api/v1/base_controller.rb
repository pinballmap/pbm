module Api
  module V1
    class BaseController < ApplicationController
      API_TOKEN_REQUIRED_MSG = "A valid api_token is required for this endpoint. Visit /api_token to request one.".freeze
      GLOBAL_RATE_LIMIT_SCOPE = "api_v1".freeze

      before_action :require_api_token, if: -> { self.class.api_token_gate_enabled? }

      rate_limit to: 120, within: 1.minute, by: :api_token_rate_limit_key, scope: GLOBAL_RATE_LIMIT_SCOPE, name: "api_v1_global",
        if: -> { self.class.api_token_gate_enabled? }, unless: -> { app_version_exempt? || token_exempt_from_rate_limit? }

      def self.api_token_gate_enabled?
        ENV.fetch("REQUIRE_API_TOKEN", "false") == "true"
      end

      private

      def require_api_token
        return if app_version_exempt?

        api_token = resolve_api_token
        if api_token
          @resolved_api_token = api_token
          @api_token_user_id = api_token.user_id
          return
        end

        render json: { error: API_TOKEN_REQUIRED_MSG }, status: :unauthorized
      end

      def app_version_exempt?
        request.headers["AppVersion"].present?
      end

      def token_exempt_from_rate_limit?
        @resolved_api_token&.exempt_from_rate_limit? || false
      end

      def api_token_rate_limit_key
        @api_token_user_id || request.remote_ip
      end

      def resolve_api_token
        token_value = params[:api_token].presence || request.headers["X-Api-Token"].presence
        return nil if token_value.blank?

        api_token = ApiToken.find_by(token: token_value)
        return nil unless api_token&.active? && !api_token.user.is_disabled?

        api_token
      end
    end
  end
end
