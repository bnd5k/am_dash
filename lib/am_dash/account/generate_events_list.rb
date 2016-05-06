require 'active_support/time'
require 'am_dash/cache_expiration'
require 'am_dash/locations/timezone_convertable'
require 'json'

module AMDash
  module Account
    class GenerateEventsList

      include AMDash::CacheExpiration
      include AMDash::Locations::TimezoneConvertable

      def initialize(cache, user_model, logger, calendar_service)
        @cache = cache
        @user_model = user_model
        @logger = logger
        @calendar_service = calendar_service
      end

      def execute(user_id)
        user = user_model.find_by_id(user_id)
        
        payload = selected_calendar_events(user)

        write_to_cache(user_id, payload.to_json)
      end

      private

      attr_reader :cache, :user_model, :logger, :calendar_service

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
        timezone = timezone_from_google(user.id)

        if !timezone
          default_timezone = "Eastern Time (US & Canada)" 
          logger.info("Unable to grab timezone for user: #{user.id}")
          timezone = default_timezone
        end

        calendar_events = calendar_service.calendar_events_list(user.id, user.email, timezone)
      end

      def timezone_from_google(user_id)
        parsed_resp = calendar_service.timezone_request(user_id)

        if parsed_resp
          google_timezone_name = parsed_resp.find { |i| i["id"] == "timezone"  }["value"]
          timezone = google_to_rails_timezone_name(google_timezone_name)
        end

        timezone 
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
