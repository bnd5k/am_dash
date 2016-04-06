require 'JSON'
require 'am_dash/cache_expiration'

module AMDash
  module Account
    class GenerateAccountSummary
      include AMDash::CacheExpiration

      def initialize(user_model, cache, coordinates_from_address)
        @user_model = user_model
        @cache = cache
        @coordinates_from_address = coordinates_from_address
      end

      def execute(user_id)
        user = user_from_id(user_id)

        account_info = {}
        if user
          account_info[:first_name] = user.first_name

          home_address_coordinates = coordinates(user.locations.home.address)
          work_address_coordinates = coordinates(user.locations.work.address)

          if home_address_coordinates
            account_info[:home_latitude] =  home_address_coordinates[:latitude]
            account_info[:home_longitude] =  home_address_coordinates[:longitude]

            update_location_records(user.locations.home, home_address_coordinates)
          end
          if work_address_coordinates
            account_info[:work_latitude] =  work_address_coordinates[:latitude]
            account_info[:work_longitude] = work_address_coordinates[:longitude]
            
            update_location_records(user.locations.work, work_address_coordinates)
          end
        end

        write_to_cache(user_id, account_info.to_json)

      end

      private

      attr_reader :user_model, :cache, :coordinates_from_address

      def update_location_records(location_record, location_coordinates)
        location_record.update_attributes(
          latitude: location_coordinates[:latitude],
          longitude: location_coordinates[:longitude]
        )
        #FIXME: it's a terrible idea to blindly update these, but this works for POC.

      end

      def coordinates(address)
        coordinates_from_address.execute(address)
      end

      def user_from_id(user_id)
        user_model.find_by_id(user_id)
      end

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
