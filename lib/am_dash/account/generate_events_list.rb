require 'active_support/time'
require 'json'
require 'am_dash/cache_expiration'
require 'am_dash/locations/timezone_convertable'
require 'google/api_client'
require 'am_dash/account/obtain_google_access_token'

module AMDash
  module Account
    class GenerateEventsList

      include AMDash::CacheExpiration
      include AMDash::Locations::TimezoneConvertable

      def initialize(cache, user_model, obtain_google_access_token, logger)
        @cache = cache
        @user_model = user_model
        @obtain_google_access_token = obtain_google_access_token
        @logger = logger
      end

      def execute(user_id)
        user = user_model.find_by_id(user_id)
        payload = selected_calendar_events(user)

        write_to_cache(user_id, payload.to_json)

      rescue AMDash::Account::ObtainGoogleAccessToken::UnableToObtainGoogleAccessTokenError
        #FIXME: seems silly to use D.I. but also require the class

        write_to_cache(user_id, [].to_json)
      end

      private

      attr_reader :cache, :user_model, :obtain_google_access_token, :logger

      def selected_calendar_events(user)
        result = []

        calendar_events = all_calendar_events(user).select { |hsh| DateTime.parse(hsh["start"]["dateTime"])  if hsh["start"] && hsh["start"]["dateTime"] }
          
        ordered_calendar_events = calendar_events.sort_by { |hsh| DateTime.parse(hsh["start"]["dateTime"]) }

        ordered_calendar_events.each do |event|
          raw_start = event["start"]["dateTime"]
          if raw_start
            formatted_start = DateTime.parse(raw_start).strftime("%l:%M %p").strip

            result << { start: formatted_start, name: event["summary"] }
          end
        end
        result
      end

      def all_calendar_events(user)
        client = authorized_client(user)
        service = client.discovered_api('calendar', 'v3')
        timezone = timezone_from_google(client, service)

        if !timezone
          default_timezone = "Eastern Time (US & Canada)" 
          logger.info("Unable to grab timezone for user: #{user.id}")
          timezone = default_timezone
        end

        response = client.execute(:api_method => service.events.list,
                                  :parameters => request_parameters(user.email, timezone),
                                  :headers => {'Content-Type' => 'application/json'}
                                 )
        parsed_response(response) || []
      end

      def timezone_from_google(client, service)
        service = client.discovered_api('calendar', 'v3')
        response = client.execute(:api_method => service.settings.list,  :headers => {'Content-Type' => 'application/json'})

        parsed_resp = parsed_response(response)
        if parsed_resp
          google_timezone_name = parsed_resp.find { |i| i["id"] == "timezone"  }["value"]
          timezone = google_to_rails_timezone_name(google_timezone_name)
        end

        timezone 
      end

      def parsed_response(raw_response)
        if raw_response.status == 200
          response_body = JSON.parse(raw_response.body)

          response_body["items"]
        end
      end

      def request_parameters(email, timezone)
        {
          "calendarId" => email,
          "timeMin" => beginning_of_day(timezone),
          "timeMax" => end_of_day(timezone)
        }
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

      def authorized_client(user)
        client = Google::APIClient.new(application_name: ENV["AM_DASH_APP_NAME"])
        client.authorization.access_token = google_access_token(user)

        client
      end

      def google_access_token(user)
        obtain_google_access_token.execute(user)
      end

      def write_to_cache(user_id, payload)
        cache.write(
          "#{user_id}-events",
          payload,
          FOUR_HOURS
        )
      end

    end
  end
end
