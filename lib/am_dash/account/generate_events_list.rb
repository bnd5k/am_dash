require 'active_support/time'
require 'json'
require 'am_dash/cache_expiration'
require 'google/api_client'

module AMDash
  module Account
    class GenerateEventsList

      include AMDash::CacheExpiration

      def initialize(cache, user_model)
        @cache = cache
        @user_model = user_model
      end

      def execute(user_id)
        user = user_model.find_by_id(user_id)
        payload = selected_calendar_events(user)

        write_to_cache(user_id, payload.to_json)
      end

      private

      attr_reader :cache, :user_model

      def selected_calendar_events(user)
        result = []
        all_calendar_events(user).each do |event|
          result << { start: event["start"]["dateTime"], name: event["summary"] }
        end
        result
      end

      def all_calendar_events(user)
        client = authorized_client(user.google_token)
        service = client.discovered_api('calendar', 'v3')
        response = client.execute(:api_method => service.events.list,
                                  :parameters => request_parameters(user.email),
                                  :headers => {'Content-Type' => 'application/json'}
                                 )

        if response.status == "200"
          response_body = JSON.parse(response.body)
          response_body["items"]
        else
          #TODO: Add logging
          []
        end
      end

      def authorized_client(token)
        #FIXME: POC does bare mininum for auth. Should be more robust.
        client = Google::APIClient.new
        client.authorization.access_token = token
        client
      end

      def request_parameters(email)
        {
          "calendarId" => email,
          "timeMin" => beginning_of_day,
          "timeMax" => end_of_day
        }
      end

      def beginning_of_day
        DateTime.now.utc.beginning_of_day.rfc3339
        #hate to pollute lib dir with Rails classes, but Google insists of RFC 3339 format 
        #and ActiveSupport already has a method for this.
      end

      def end_of_day
        DateTime.now.utc.end_of_day.rfc3339
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
