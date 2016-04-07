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
        five_day_forecast = all_weather(location.latitude, location.longitude)
        forecast_for_today = five_day_forecast.first(8) # 24 hours in day / forecast results in 3 hr intervals

        result = []
        forecast_for_today.map  do |weather_data|
          result << { time: weather_data["dt"], temp: weather_data["main"]["temp"] }
        end
        result
      end

      def all_weather(latitude, longitude)
        request = request_uri(latitude, longitude)
        response = Net::HTTP.get_response(request)

        if response.code == "200"
          response_body = JSON.parse(response.body)
          response_body["list"]
        else
          []
        end
      end

      def request_uri(latitude, longitude)
        uri = URI("http://api.openweathermap.org/data/2.5/forecast")

        params = {
          lat: latitude,
          lon: longitude,
          units: :imperial,
          appid: ENV["AM_DASH_OPEN_WEATHER_KEY"]
        }

        uri.query = URI.encode_www_form(params)

        uri
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
