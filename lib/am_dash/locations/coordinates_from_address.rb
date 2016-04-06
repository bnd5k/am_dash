module AMDash
  module Locations
    class CoordinatesFromAddress

      def initialize(geocoder)
        @geocoder = geocoder
      end

      def execute(address)
        geo_data = @geocoder.search(address).first
        if geo_data
          { latitude: geo_data.coordinates[0], longitude: geo_data.coordinates[1] }
        end
      end

      attr_reader :geocoder

    end
  end
end
