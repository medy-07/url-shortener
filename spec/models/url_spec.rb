require "rails_helper"

RSpec.describe Url, type: :model do
  describe "validations" do
    subject { build(:url) }

    it { is_expected.to validate_presence_of(:long_url) }
    it { is_expected.to validate_length_of(:long_url).is_at_most(2048) }
    it { is_expected.to validate_presence_of(:short_code) }
    it { is_expected.to validate_uniqueness_of(:short_code) }

    it "accepts http and https URLs" do
      expect(build(:url, long_url: "http://example.com")).to be_valid
      expect(build(:url, long_url: "https://example.com/a?b=c#d")).to be_valid
    end

    it "rejects non-http(s) and malformed URLs" do
      [ "ftp://example.com", "javascript:alert(1)", "example.com", "https://", "http://exa mple.com" ].each do |bad|
        url = build(:url, long_url: bad)
        expect(url).not_to be_valid, "expected #{bad.inspect} to be invalid"
        expect(url.errors[:long_url]).to include("must be a valid http(s) URL")
      end
    end

    it "rejects an expiry in the past on create" do
      expect(build(:url, expires_at: 1.minute.ago)).not_to be_valid
    end
  end

  describe "#expired?" do
    it "is false without an expiry" do
      expect(build(:url, expires_at: nil)).not_to be_expired
    end

    it "is false before the expiry" do
      expect(build(:url, expires_at: 1.hour.from_now)).not_to be_expired
    end

    it "is true after the expiry" do
      expect(build(:url, expires_at: 1.second.ago)).to be_expired
    end
  end

  describe "#redirectable?" do
    it "is true when active and not expired" do
      expect(build(:url)).to be_redirectable
    end

    it "is false when inactive" do
      expect(build(:url, is_active: false)).not_to be_redirectable
    end

    it "is false when expired" do
      expect(build(:url, expires_at: 1.second.ago)).not_to be_redirectable
    end
  end
end
