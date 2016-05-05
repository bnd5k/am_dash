require 'net/http'
require 'json'

module AMDash
  module Account
    class ObtainGoogleAccessToken

      def initialize(user_model)
        @user_model = user_model
      end

      def execute(user_id)
        user = user_model.find_by_id(user_id) 
        raise UserNotFoundError unless user

        if user.google_token && user.google_refresh_token
          token = find_or_request_google_access_token(user)
          token
        else
          raise UnableToObtainGoogleAccessTokenError
        end
      end

      private

      attr_reader :user_model

      def find_or_request_google_access_token(user)
        if Time.at(user.google_token_expiration.to_i).utc <=  Time.now.utc
          request_new_google_access_token(user)
        else
          user.google_token
        end
      end

      def request_new_google_access_token(user)
        google_data = parsed_response(user)
        if google_data

          token = google_data["access_token"]

          expiration = Time.now.to_i + google_data["expires_in"]
          user.update_attributes(google_token: token,
                                 google_token_expiration: expiration)
          token
        else
          #TODO: log something
        end
      end

      def parsed_response(user)
        resp = response(user)

        if resp.code == "200"
          JSON.parse(resp.body)
        end
      end

      def response(user)
        uri = URI("https://accounts.google.com/o/oauth2/token")

        params =  { 'refresh_token' => user.google_refresh_token,
                    'client_id' => ENV['AM_DASH_GOOGLE_KEY'],
                    'client_secret' => ENV['AM_DASH_GOOGLE_SECRET'],
                    'grant_type' => 'refresh_token'
        }

        Net::HTTP.post_form(uri, params)
      end

      class UnableToObtainGoogleAccessTokenError < StandardError ; end
      class UserNotFoundError < StandardError ; end

    end
  end
end
