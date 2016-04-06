require 'am_dash/account/find_or_create_from_google'
require 'am_dash/locations/create'

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

  end
end
