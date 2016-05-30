require 'json'
require 'google/api_client'
require 'am_dash/google/obtain_google_access_token'
require 'active_support/time'

#AMDash::Google::APIRequestService::UnableToObtainGoogleAccessTokenError
#
module AMDash
  module Google
    class APIRequestService


      def initialize(obtain_google_access_token, logger)
        @obtain_google_access_token = obtain_google_access_token
        @logger = logger
      end

      def timezone_request(user_id)
        client = authorized_client(user_id)

        service = calendar_service(client) 

        response = client.execute(
          :api_method => service.settings.list,
          :headers => { 'Content-Type' => 'application/json' }
        )

        parsed_response(response)

      rescue AMDash::Google::ObtainGoogleAccessToken::UnableToObtainGoogleAccessTokenError => e
        logger.info("Failed to request calendar timezone. Unable to obtain Google Access Token for user #{user_id}:\n #{e.backtrace}")
        return []
      end

      def calendar_events_list(user_id, user_email, timezone)
        client = authorized_client(user_id)

        service = calendar_service(client) 

        response = client.execute(:api_method => service.events.list,
                                  :parameters => request_parameters(user_email, timezone),
                                  :headers => {'Content-Type' => 'application/json'}
                                 )

        parsed_response(response)

      rescue AMDash::Google::ObtainGoogleAccessToken::UnableToObtainGoogleAccessTokenError => e
        logger.info("Failed to resquest calendar events. Unable to obtain Google Access Token for user #{user_id} :\n #{e.backtrace}")
        return []
      end

      private

      attr_reader :obtain_google_access_token, :logger

      def authorized_client(user_id)
        @google_client ||= setup_authorized_client(user_id)
      end

      def setup_authorized_client(user_id)
        client = ::Google::APIClient.new(application_name: ENV["AM_DASH_APP_NAME"])
        client.authorization.access_token = google_access_token(user_id)

        client
      end

      def google_access_token(user_id)
        obtain_google_access_token.execute(user_id)
      end

      def parsed_response(raw_response)
        if raw_response.status == 200
          response_body = JSON.parse(raw_response.body)

          response_body["items"]
        else
          logger.info("Bad Google Response. Status: #{raw_response.status}, body: #{raw_response.body}")
          []
        end
      end

      def request_parameters(email, timezone)
        {
          "calendarId" => email,
          "timeMin" => beginning_of_day(timezone),
          "timeMax" => end_of_day(timezone)
        }
      end

      def calendar_service(client)
        client.discovered_api('calendar', 'v3')
      end

      def beginning_of_day(timezone)
        day_beginning = DateTime.now.in_time_zone(timezone).beginning_of_day
        rfc3339_formatting(day_beginning)
      end

      def end_of_day(timezone)
        day_end = DateTime.now.in_time_zone(timezone).end_of_day
        rfc3339_formatting(day_end)
      end

      def rfc3339_formatting(date_time_object)
        #Google insists of RFC 3339 format 
        date_time_object.strftime("%FT%T%z")
      end
    end
  end
end
