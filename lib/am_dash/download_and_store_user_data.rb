module AMDash
  class DownloadAndStoreUserData

    def initialize(account_summary, events, weather_forecast, news)
      @account_summary = account_summary
      @events = events
      @weather_forecast = weather_forecast
      @news = news
    end

    def execute(user_id)
      account_summary.execute(user_id)
      events.execute(user_id)
      weather_forecast.execute(user_id)
      news.execute
    end

    attr_reader :account_summary, :events, :weather_forecast, :news

  end
end
