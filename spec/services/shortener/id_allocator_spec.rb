require "rails_helper"

RSpec.describe Shortener::IdAllocator do
  subject(:allocator) { described_class.new }

  it "hands out no duplicate ids across 5,000 calls" do
    ids = Array.new(5_000) { allocator.next_id }
    expect(ids.uniq.size).to eq(5_000)
  end

  it "hands out ids from block 1 first, then reserves the next block" do
    ids = Array.new(1_001) { allocator.next_id }
    expect(ids.first(1_000)).to eq((1_000..1_999).to_a)
    expect(ids.last).to eq(2_000)
  end

  it "reserves a block per 1,000 ids in the database" do
    2_500.times { allocator.next_id }
    value = ActiveRecord::Base.connection.select_value(
      "SELECT value FROM id_counters WHERE name = 'url_blocks'"
    )
    expect(value).to eq(3)
  end

  it "never gives two allocators the same id" do
    other = described_class.new
    ids = Array.new(1_500) { allocator.next_id } + Array.new(1_500) { other.next_id }
    expect(ids.uniq.size).to eq(3_000)
  end

  it "is thread-safe" do
    allocator.next_id # reserve on this thread's connection first
    ids = Array.new(4) { Thread.new { Array.new(200) { allocator.next_id } } }.flat_map(&:value)
    expect(ids.uniq.size).to eq(800)
  end
end
