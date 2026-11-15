class AppVersion < ApplicationRecord
  PLATFORMS = %w[ios android].freeze

  validates :platform, presence: true, inclusion: { in: PLATFORMS }, uniqueness: true
  validates :latest, presence: true, format: { with: /\A\d+(\.\d+)*\z/, message: "must look like 5.5.1" }

  def platform_enum
    PLATFORMS
  end
end
