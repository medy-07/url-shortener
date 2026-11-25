module Shortener
  # Hands out unique ids from in-process blocks of BLOCK_SIZE. A new block is
  # reserved atomically in the database, so ids never repeat across processes.
  # Block n covers ids n*BLOCK_SIZE ... n*BLOCK_SIZE + BLOCK_SIZE - 1. The first
  # block reserved is 1, so ids start at BLOCK_SIZE.
  class IdAllocator
    BLOCK_SIZE = 1_000
    COUNTER_NAME = "url_blocks"

    RESERVE_BLOCK_SQL = <<~SQL.squish
      INSERT INTO id_counters (name, value) VALUES ($1, 1)
      ON CONFLICT (name) DO UPDATE SET value = id_counters.value + 1
      RETURNING value
    SQL

    class << self
      def instance
        @instance ||= new
      end

      def next_id
        instance.next_id
      end

      # Drops the cached block, e.g. after test transactions roll the counter back.
      def reset!
        @instance = nil
      end
    end

    def initialize(block_size: BLOCK_SIZE, counter_name: COUNTER_NAME)
      @block_size = block_size
      @counter_name = counter_name
      @mutex = Mutex.new
      @next = nil
      @limit = nil
    end

    def next_id
      @mutex.synchronize do
        reserve_block if @next.nil? || @next >= @limit
        id = @next
        @next += 1
        id
      end
    end

    private

    def reserve_block
      block = ActiveRecord::Base.connection.select_value(
        RESERVE_BLOCK_SQL, "IdAllocator reserve block", [ @counter_name ]
      ).to_i
      @next = block * @block_size
      @limit = @next + @block_size
    end
  end
end
