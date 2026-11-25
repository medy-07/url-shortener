class Url < ApplicationRecord
  MAX_LONG_URL_LENGTH = 2048
  ALLOWED_SCHEMES = %w[http https].freeze

  validates :long_url, presence: true, length: { maximum: MAX_LONG_URL_LENGTH }
  validate :long_url_must_be_http_url
  validates :short_code, presence: true, uniqueness: true
  validate :expires_at_must_be_in_future, on: :create

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def redirectable?
    is_active? && !expired?
  end

  private

  def long_url_must_be_http_url
    return if long_url.blank?

    uri = URI.parse(long_url)
    valid = ALLOWED_SCHEMES.include?(uri.scheme&.downcase) && uri.host.present?
    errors.add(:long_url, "must be a valid http(s) URL") unless valid
  rescue URI::InvalidURIError
    errors.add(:long_url, "must be a valid http(s) URL")
  end

  def expires_at_must_be_in_future
    errors.add(:expires_at, "must be in the future") if expired?
  end
end
