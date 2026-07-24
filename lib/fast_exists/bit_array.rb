# frozen_string_literal: true

require "thread"

module FastExists
  class BitArray
    attr_reader :size

    def initialize(size)
      raise InvalidArgumentError, "BitArray size must be positive" if size <= 0

      @size = size
      @bytesize = (size + 7) / 8
      @bytes = ("\x00" * @bytesize).b
      @mutex = Mutex.new
    end

    def set(index)
      validate_index!(index)
      byte_idx = index / 8
      bit_idx = index % 8

      @mutex.synchronize do
        current_byte = @bytes.getbyte(byte_idx)
        new_byte = current_byte | (1 << bit_idx)
        @bytes.setbyte(byte_idx, new_byte)
      end
      true
    end

    def set?(index)
      validate_index!(index)
      byte_idx = index / 8
      bit_idx = index % 8

      byte = @bytes.getbyte(byte_idx)
      (byte & (1 << bit_idx)) != 0
    end

    alias get set?

    def clear
      @mutex.synchronize do
        @bytes = ("\x00" * @bytesize).b
      end
      true
    end

    def count_ones
      count = 0
      @bytes.each_byte do |b|
        # Kernighan's popcount per byte
        while b > 0
          count += 1
          b &= (b - 1)
        end
      end
      count
    end

    alias popcount count_ones

    def bytesize
      @bytesize
    end

    def to_s
      @mutex.synchronize { @bytes.dup }
    end

    def self.from_s(raw_bytes, size)
      bit_array = new(size)
      bit_array.to_s_load(raw_bytes)
      bit_array
    end

    def to_s_load(raw_bytes)
      @mutex.synchronize do
        raise InvalidArgumentError, "Byte length mismatch" if raw_bytes.bytesize != @bytesize
        @bytes = raw_bytes.dup.b
      end
    end

    private

    def validate_index!(index)
      raise IndexError, "index #{index} out of bounds (0...#{@size})" if index < 0 || index >= @size
    end
  end
end
