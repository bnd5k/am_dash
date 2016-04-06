class DashboardController < ApplicationController

  before_action :authenticate_user!, :ensure_registration_complete

  def index
  end

end
