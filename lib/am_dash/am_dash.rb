require 'am_dash/account/find_or_create_from_google'
require 'am_dash/account/update_location_coordinates'
require 'am_dash/account/generate_account_summary'
require 'am_dash/account/generate_events_list'
require 'am_dash/locations/create'
require 'am_dash/locations/coordinates_from_address'
require 'am_dash/news/generate_recent_articles_list'
require 'am_dash/weather/generate_weather_forecast'
require 'am_dash/download_and_store_user_data'
require 'am_dash/cache'
require 'geocoder'

module AMDash 
  class << self

    def find_or_create_from_google
      AMDash::Account::FindOrCreateFromGoogle.new(::User)
    end

    def create_location
      AMDash::Locations::Create.new(Location)
    end

    def download_and_store_user_data
      DownloadAndStoreUserData.new(
        generate_account_summary,
        generate_events_list,
        generate_weather_forecast,
        generate_recent_article_list
      )
    end

    def generate_account_summary
      AMDash::Account::GenerateAccountSummary.new(
        ::User,
        cache,
        update_location_coordinates
      )
    end

    def generate_events_list
      AMDash::Account::GenerateEventsList.new(cache, ::User)
    end

    def generate_recent_article_list
      AMDash::News::GenerateRecentArticlesList.new(cache)
    end

    def generate_weather_forecast
      AMDash::Weather::GenerateWeatherForecast.new(
        ::User,
        cache,
        update_location_coordinates
      )
    end

    private

    def update_location_coordinates
     AMDash::Account::UpdateLocationCoordinates.new(::User, coordinates_from_address)
    end

    def coordinates_from_address
      AMDash::Locations::CoordinatesFromAddress.new(Geocoder)
    end

    def cache
      AMDash::Cache
    end

  end
end
