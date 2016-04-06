require 'am_dash/am_dash'

class LocationsController < ApplicationController

  before_filter :authenticate_user!

  def new
    @home = Location.new
    @work = Location.new
  end

  def create
    @home, @work = AMDash.create_location(params[:home_address], params[:work_address], current_user.id)
    if !@home.errors.any? && !@work.errors.any?
      redirect_to root_url
    else
      flash[:error] = "Something went wrong. Please try again."
      render :new
    end
  end

end
