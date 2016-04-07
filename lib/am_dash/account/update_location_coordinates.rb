module AMDash
  module Account
    class UpdateLocationCoordinates

      def initialize(user_model, coordinates_from_address)
        @user_model = user_model
        @coordinates_from_address = coordinates_from_address
      end

      def execute(user_id)
        user = user_model.find_by_id(user_id)
        home = user.locations.home
        work = user.locations.work

        [home,work].each do |location|
          update_coordinates_if_needed(location)
        end

        [home, work]
      end

      private

      attr_reader :user_model, :coordinates_from_address

      def update_coordinates_if_needed(location)
        coords = coordinates_from_address.execute(location.address)

        if coordinate_update_needed?(coords, location)
          update_location_records(location, coords)
        end
      end

      def coordinate_update_needed?(coordinates, location_record)
        coordinates && 
          (coordinates[:latitude] != location_record.latitude) && 
          (coordinates[:longitude] != location_record.longitude) 
      end

      def update_location_records(location_record, location_coordinates)
        location_record.update_attributes(
          latitude: location_coordinates[:latitude],
          longitude: location_coordinates[:longitude]
        )
      end

    end
  end
end
