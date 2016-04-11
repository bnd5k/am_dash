module AMDash
  module Locations
    module TimezoneConvertable

      def google_to_rails_timezone_name(google_timezone_name)
        if google_timezone_name
          case google_timezone_name.to_sym
          when :"America/Los_Angeles"
            "Pacific Time (US & Canada)"
          when :"America/Denver"
            "Mountain Time (US & Canada)"
          when :"America/Chicago" 
            "Central Time (US & Canada)"
          when :"America/New_York"
            "Eastern Time (US & Canada)" 
          end
        end
      end

    end
  end
end
