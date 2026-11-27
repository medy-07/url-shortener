module Shortener
  class Create
    ALIAS_FORMAT = /\A[0-9a-zA-Z_-]{3,32}\z/
    MAX_GENERATION_ATTEMPTS = 3

    def self.call(...)
      new(...).call
    end

    def initialize(long_url:, alias_code: nil, expires_at: nil, allocator: IdAllocator)
      @long_url = long_url
      @alias_code = alias_code.presence
      @expires_at = expires_at
      @allocator = allocator
    end

    # Returns the Url: persisted on success, otherwise carrying its errors.
    def call
      @alias_code ? create_with_alias : create_with_generated_code
    end

    private

    def create_with_alias
      url = build_url(@alias_code)
      unless ALIAS_FORMAT.match?(@alias_code)
        url.validate
        url.errors.add(:short_code, "may only contain letters, digits, '-' and '_' (3-32 characters)")
        return url
      end

      url.errors.add(:short_code, :taken) if save_unique(url) == :taken
      url
    end

    # A generated code can only clash with a custom alias that happens to look
    # like one. When that happens, move on to the next id.
    def create_with_generated_code
      MAX_GENERATION_ATTEMPTS.times do
        url = build_url
        return url unless save_unique(url) == :taken
      end

      build_url.tap do |url|
        url.validate
        url.errors.add(:short_code, "could not be generated, please retry")
      end
    end

    def build_url(code = nil)
      id = @allocator.next_id
      Url.new(id: id, short_code: code || Base62.from_id(id), long_url: @long_url, expires_at: @expires_at)
    end

    # Returns :saved, :invalid, or :taken when only the short code clashes.
    # The unique index catches races that the uniqueness validation misses.
    def save_unique(url)
      return :saved if url.save
      return :taken if url.errors.attribute_names == [ :short_code ] && url.errors.of_kind?(:short_code, :taken)

      :invalid
    rescue ActiveRecord::RecordNotUnique
      :taken
    end
  end
end
