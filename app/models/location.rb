require 'am_dash/locations/categories'

class Location < ActiveRecord::Base
  include AMDash::Locations::Categories

  validates_presence_of :address, :user_id, :category

end
