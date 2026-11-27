require "rails_helper"

RSpec.describe Shortener::Create do
  it "creates a url with a generated 7-character code derived from its id" do
    url = described_class.call(long_url: "https://example.com")

    expect(url).to be_persisted
    expect(url.short_code).to eq(Shortener::Base62.from_id(url.id))
    expect(url.short_code.length).to eq(7)
  end

  it "uses a custom alias" do
    url = described_class.call(long_url: "https://example.com", alias_code: "my-link")
    expect(url).to be_persisted
    expect(url.short_code).to eq("my-link")
  end

  it "rejects a taken alias" do
    described_class.call(long_url: "https://example.com", alias_code: "my-link")
    url = described_class.call(long_url: "https://example.org", alias_code: "my-link")

    expect(url).not_to be_persisted
    expect(url.errors[:short_code]).to include("has already been taken")
  end

  it "rejects a malformed alias" do
    url = described_class.call(long_url: "https://example.com", alias_code: "bad alias!")
    expect(url).not_to be_persisted
    expect(url.errors[:short_code]).to be_present
  end

  it "skips to the next id when a generated code is already taken by an alias" do
    allocator = Shortener::IdAllocator.new
    clashing_code = Shortener::Base62.from_id(1_000) # the first id this allocator will hand out
    create(:url, id: 1, short_code: clashing_code)

    url = described_class.new(long_url: "https://example.com", allocator: allocator).call

    expect(url).to be_persisted
    expect(url.id).to eq(1_001)
  end

  it "returns an unsaved url with errors for an invalid long url" do
    url = described_class.call(long_url: "not a url")
    expect(url).not_to be_persisted
    expect(url.errors[:long_url]).to be_present
  end

  it "stores the expiry" do
    expires_at = 1.day.from_now.change(usec: 0)
    url = described_class.call(long_url: "https://example.com", expires_at: expires_at)
    expect(url.reload.expires_at).to eq(expires_at)
  end
end
