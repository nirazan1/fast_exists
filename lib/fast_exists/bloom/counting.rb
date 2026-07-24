# frozen_string_literal: true

require "zlib"
require "digest"

module FastExists
  module Bloom
    class Counting
      attr_reader :expected_elements, :false_positive_rate, :count, :counter_size

      def initialize(expected_elements: 10_000, false_positive_rate: 0.001)
        @expected_elements = expected_elements
        @false_positive_rate = false_positive_rate
        @count = 0
        @mutex = Mutex.new

        @bit_size = (-(expected_elements * Math.log(false_positive_rate)) / (Math.log(2)**2)).ceil
        @hash_count = [((@bit_size.to_f / expected_elements) * Math.log(2)).round, 1].max
        @counters = Array.new(@bit_size, 0)
      end

      def add(element)
        indexes = hash_indexes(element.to_s)
        @mutex.synchronize do
          indexes.each do |idx|
            @counters[idx] += 1 if @counters[idx] < 255
          end
          @count += 1
        end
        true
      end

      def contains?(element)
        indexes = hash_indexes(element.to_s)
        @mutex.synchronize do
          indexes.all? { |idx| @counters[idx] > 0 }
        end
      end

      def delete(element)
        return false unless contains?(element)

        indexes = hash_indexes(element.to_s)
        @mutex.synchronize do
          indexes.each do |idx|
            @counters[idx] -= 1 if @counters[idx] > 0
          end
          @count = [@count - 1, 0].max
        end
        true
      end

      def clear
        @mutex.synchronize do
          @counters.fill(0)
          @count = 0
        end
        true
      end

      def stats
        @mutex.synchronize do
          {
            type: :counting_bloom,
            inserted_items: @count,
            bit_size: @bit_size,
            hash_count: @hash_count,
            memory_usage_bytes: @counters.size
          }
        end
      end

      private

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
