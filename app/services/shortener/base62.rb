module Shortener
  module Base62
    ALPHABET = ("0".."9").to_a + ("a".."z").to_a + ("A".."Z").to_a
    BASE = ALPHABET.size # 62
    CODE_LENGTH = 7
    SPACE = BASE**CODE_LENGTH # 62**7 ≈ 3.5 trillion

    # Odd and not a multiple of 31, so coprime with 62**7: multiplication
    # modulo SPACE is a bijection, meaning distinct ids give distinct codes.
    MULTIPLIER = 1_000_000_007

    module_function

    def from_id(id)
      id = Integer(id)
      raise ArgumentError, "id must be in 0...#{SPACE}, got #{id}" unless id >= 0 && id < SPACE

      encode((id * MULTIPLIER) % SPACE).rjust(CODE_LENGTH, ALPHABET.first)
    end

    def encode(number)
      return ALPHABET.first if number.zero?

      digits = []
      while number.positive?
        number, remainder = number.divmod(BASE)
        digits << ALPHABET[remainder]
      end
      digits.reverse.join
    end
  end
end
