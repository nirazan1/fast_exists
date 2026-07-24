# frozen_string_literal: true

require "zlib"
require "digest"

module FastExists
  module Bloom
    class Filter
      attr_reader :expected_elements, :false_positive_rate, :bit_size, :hash_count, :count

      def initialize(expected_elements: 1_000_000, false_positive_rate: 0.001, bit_array: nil)
        raise InvalidArgumentError, "expected_elements must be > 0" if expected_elements <= 0
        raise InvalidArgumentError, "false_positive_rate must be between 0 and 1" if false_positive_rate <= 0 || false_positive_rate >= 1

        @expected_elements = expected_elements
        @false_positive_rate = false_positive_rate
        @count = 0
        @mutex = Mutex.new

        @bit_size = calculate_bit_size(expected_elements, false_positive_rate)
        @hash_count = calculate_hash_count(@bit_size, expected_elements)
        @bit_array = bit_array || FastExists::BitArray.new(@bit_size)
      end

      def add(element)
        key = element.to_s
        indexes = hash_indexes(key)

        indexes.each do |idx|
          @bit_array.set(idx)
        end

        @mutex.synchronize do
          @count += 1
        end
        true
      end

      def contains?(element)
        key = element.to_s
        indexes = hash_indexes(key)

        indexes.all? { |idx| @bit_array.set?(idx) }
      end

      def clear
        @mutex.synchronize do
          @bit_array.clear
          @count = 0
        end
        true
      end

      def capacity
        @expected_elements
      end

      def occupancy
        set_bits = @bit_array.count_ones
        set_bits.to_f / @bit_size
      end

      def estimated_false_positive_rate
        # p = (1 - e^(-k * n / m))^k
        exponent = -(@hash_count * @count.to_f) / @bit_size
        (1.0 - Math::E**exponent)**@hash_count
      end

      def memory_usage_bytes
        @bit_array.bytesize
      end

      def stats
        {
          expected_elements: @expected_elements,
          false_positive_rate: @false_positive_rate,
          estimated_false_positive_rate: estimated_false_positive_rate,
          inserted_items: @count,
          bit_size: @bit_size,
          hash_count: @hash_count,
          occupancy: occupancy,
          memory_usage_bytes: memory_usage_bytes
        }
      end

      def dump
        {
          expected_elements: @expected_elements,
          false_positive_rate: @false_positive_rate,
          count: @count,
          bit_size: @bit_size,
          hash_count: @hash_count,
          bytes: @bit_array.to_s
        }
      end

      def self.load(dump_data)
        filter = new(
          expected_elements: dump_data[:expected_elements],
          false_positive_rate: dump_data[:false_positive_rate]
        )
        filter.instance_variable_set(:@count, dump_data[:count])
        filter.bit_array.to_s_load(dump_data[:bytes])
        filter
      end

      attr_reader :bit_array

      private

      def calculate_bit_size(n, p)
        # m = - (n * ln(p)) / (ln(2)^2)
        m = (-(n * Math.log(p)) / (Math.log(2)**2)).ceil
        [m, 64].max
      end

      def calculate_hash_count(m, n)
        # k = (m / n) * ln(2)
        k = ((m.to_f / n) * Math.log(2)).round
        [k, 1].max
      end

      def hash_indexes(key)
        h1 = Zlib.crc32(key)
        h2 = Digest::SHA256.hexdigest(key)[0..7].hex

        Array.new(@hash_count) do |i|
          (h1 + i * h2) % @bit_size
        end
      end
    end
  end
end
