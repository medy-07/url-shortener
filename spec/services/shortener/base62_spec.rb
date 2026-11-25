require "rails_helper"

RSpec.describe Shortener::Base62 do
  describe ".from_id" do
    it "returns a 7-character base62 code" do
      [ 0, 1, 1_000, 123_456_789, described_class::SPACE - 1 ].each do |id|
        expect(described_class.from_id(id)).to match(/\A[0-9a-zA-Z]{7}\z/)
      end
    end

    it "gives unique codes for 10,000 ids" do
      codes = (1..10_000).map { |id| described_class.from_id(id) }
      expect(codes.uniq.size).to eq(10_000)
    end

    it "does not produce sequential codes for sequential ids" do
      expect(described_class.from_id(1001)).not_to eq(described_class.from_id(1000).succ)
    end

    it "is deterministic" do
      expect(described_class.from_id(42)).to eq(described_class.from_id(42))
    end

    it "rejects ids outside the code space" do
      expect { described_class.from_id(-1) }.to raise_error(ArgumentError)
      expect { described_class.from_id(described_class::SPACE) }.to raise_error(ArgumentError)
    end
  end

  describe ".encode" do
    it "encodes using the 0-9a-zA-Z alphabet" do
      expect(described_class.encode(0)).to eq("0")
      expect(described_class.encode(10)).to eq("a")
      expect(described_class.encode(61)).to eq("Z")
      expect(described_class.encode(62)).to eq("10")
    end
  end
end
