require 'json'
require 'am_dash/cache_expiration'

module AMDash
  module Account
    class GenerateAccountSummary
      include AMDash::CacheExpiration

      def initialize(user_model, cache, update_location_coordinates)
        @user_model = user_model
        @cache = cache
        @update_location_coordinates = update_location_coordinates
      end

      def execute(user_id)
        user = user_model.find_by_id(user_id)

        account_info = {}
        if user
          home, work = update_location_coordinates.execute(user.id)

          account_info[:first_name] = user.first_name

          account_info[:home_latitude] =  home.latitude
          account_info[:home_longitude] =  home.longitude

          account_info[:work_latitude] =  work.latitude
          account_info[:work_longitude] = work.longitude
        end

        write_to_cache(user_id, account_info.to_json)

      end

      private

      attr_reader :user_model, :cache, :update_location_coordinates

      def write_to_cache(user_id, payload)
        cache.write(
          "#{user_id}-account",
          payload,
          FOUR_HOURS
        )
      end

    end
  end
end
