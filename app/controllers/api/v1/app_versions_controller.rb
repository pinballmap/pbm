module Api
  module V1
    class AppVersionsController < BaseController
      skip_before_action :verify_authenticity_token

      before_action :allow_cors

      api :GET, "/api/v1/app_versions.json", "Fetch the latest released version of the mobile app"
      description "Returns ios and android keys, each with latest. latest is null if no version has been set for that platform."
      formats [ "json" ]
      def index
        versions = AppVersion.pluck(:platform, :latest).to_h
        render json: AppVersion::PLATFORMS.index_with { |platform| { latest: versions[platform] } }
      end
    end
  end
end
