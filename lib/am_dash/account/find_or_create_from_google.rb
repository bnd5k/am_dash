require 'securerandom'

module AMDash 
  module Account
    class FindOrCreateFromGoogle

      def initialize(user_model, logger)
        @user_model = user_model
        @logger = logger
      end

      def execute(auth_data)
        if auth_data
          account = user_model.where(google_uid: auth_data["uid"]).first

          if account
            logger.info("Found user #{account.id} from OmniAuth payload")
          else

            account_data = { 
              first_name: auth_data["info"]["first_name"],
              email: auth_data["info"]["email"],
              google_uid: auth_data["uid"],
              google_token: auth_data["credentials"]["token"],
              google_refresh_token: auth_data["credentials"]["refresh_token"],
              google_token_expiration: auth_data["credentials"]["expires_at"],
              password: SecureRandom.base64(16)
            }
            account = user_model.create!(account_data)

            logger.info("Created User with email '#{account.email}' from OmniAuth payload")
          end

          account
        end
      end

      attr_reader :user_model, :logger

    end
  end
end
