require 'net/http'
require 'JSON'
require 'am_dash/cache_expiration'

module AMDash
  module Weather
    class GenerateWeatherForecast
      include AMDash::CacheExpiration

      def initialize(user_model, cache, update_location_coordinates)
        @user_model = user_model
        @cache = cache
        @update_location_coordinates = update_location_coordinates
      end

      def execute(user_id)
        user = user_model.find_by_id(user_id)

        payload = []

        if user
          home, work = update_location_coordinates.execute(user.id)
          payload = upcoming_weather(home)
        end

        write_to_cache(user_id, payload.to_json)
      end

      private

      attr_reader :user_model, :cache, :update_location_coordinates

      def upcoming_weather(location)
        forecast_for_today = all_weather(location.latitude, location.longitude)["hourly"]["data"]

        result = []

        forecast_for_today.each do |weather_data|
          hour = Time.at(weather_data["time"]).hour
          if selectable_time?(hour)
            result << { time: hour, temp: weather_data["temperature"] }
          end
        end

        result
      end

      def selectable_time?(hour)
        # grab 6am, 9am, 12pm, 3pm, 6pm, and 9pm
        (6..21) === hour && (hour % 3 == 0)
      end

      def all_weather(latitude, longitude)
        request  = URI("https://api.forecast.io/forecast/#{ENV["AM_DASH_FORECAST_IO_KEY"]}/#{latitude},#{longitude},#{Time.now.to_i}")
        response = Net::HTTP.get_response(request)

        if response.code == "200"
          response_body = JSON.parse(response.body)
        else
          []
        end
      end

      def write_to_cache(user_id, payload)
        cache.write(
          "#{user_id}-weather",
          payload,
          FOUR_HOURS
        )
      end

    end
  end
end
