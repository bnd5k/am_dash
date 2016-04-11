require 'am_dash/am_dash'
require 'am_dash/worker'

class DashboardController < ApplicationController

  before_action :authenticate_user!, :ensure_registration_complete
  before_action :verify_user_data_present, only: [:index]

  def index
    @account_summary = JSON.parse(account_summary_store)
    @weather_forecast = JSON.parse(weather_store)
    @events = JSON.parse(events_store)
    @news_articles = JSON.parse(news_store)
  end

  def loading

  end

  def status
    render :json => (stored_data_present? ? 1 : 0)
  end

  private

  def verify_user_data_present
    unless stored_data_present?
      redirect_to loading_path
      AMDash::Worker.enqueue(:download_and_store_user_data, current_user.id)
    end
  end

  def stored_data_present?
    account_summary_store && weather_store && events_store && news_store
    #note that if API calls fails to download and store data, we'll at least have some object,
    #even if it's just an empty array or empty hash
  end

  def account_summary_store
    data_store("#{current_user.id}-account")
  end

  def weather_store
    data_store("#{current_user.id}-weather")
  end

  def events_store
    data_store("#{current_user.id}-events")
  end

  def news_store
    data_store("news")
  end

  def data_store(key)
    AMDash::Cache.read(key) 
  end

end
