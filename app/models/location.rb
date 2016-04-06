require 'am_dash/locations/categories'

class Location < ActiveRecord::Base
  include AMDash::Locations::Categories

  validates_presence_of :address, :user_id, :category

  scope :home, -> { where(category: AMDash::Locations::Categories::LOCATION_CATEGORIES[:home]).first }
  scope :work, -> { where(category: AMDash::Locations::Categories::LOCATION_CATEGORIES[:work]).first }
end
