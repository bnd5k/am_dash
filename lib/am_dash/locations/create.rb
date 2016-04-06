require 'am_dash/locations/categories'

module AMDash 
  module Locations
    class Create
      include Categories

      def initialize(location_model)
        @location_model = location_model
      end

      def execute(home_address, work_address, user_id)

          home = location_model.new(
            address: home_address,
            user_id: user_id,
            category: LOCATION_CATEGORIES[:home]
          )

          work = location_model.new(
            address: work_address,
            user_id: user_id,
            category: LOCATION_CATEGORIES[:work]
          )

          if home.valid? && work.valid?
            home.save! && work.save!
          end

          [home, work]
      end
      
      attr_reader :location_model

    end
  end
end

