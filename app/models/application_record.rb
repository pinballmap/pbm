class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def skip_geocoding?
    ENV['SKIP_GEOCODE'] || (:lat && :lon)
  end
end
