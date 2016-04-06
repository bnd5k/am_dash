require 'am_dash/account/find_or_create_from_google'
require 'am_dash/locations/create'
require 'am_dash/locations/coordinates_from_address'
require 'am_dash/cache'
require 'geocoder'

module AMDash 
  class << self

    def find_or_create_from_google(auth_data)
      context = AMDash::Account::FindOrCreateFromGoogle.new(User)
      context.execute(auth_data)
    end

    def create_location(home_address, work_address, user_id)
      context = AMDash::Locations::Create.new(Location)
      context.execute(home_address, work_address, user_id)
    end

    def generate_account_summary(user_id)
      context = AMDash::Account::GenerateAccountSummary.new(
        User,
        cache,
        coordinates_from_address
      )
      context.execute(user_id)
    end

    private

    def coordinates_from_address
      AMDash::Locations::CoordinatesFromAddress.new(Geocoder)
    end

    def cache
      AMDash::Cache
    end

  end
end
