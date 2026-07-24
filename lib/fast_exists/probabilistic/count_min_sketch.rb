# frozen_string_literal: true

require "zlib"
require "digest"

module FastExists
  module Probabilistic
    class CountMinSketch
      attr_reader :width, :depth

      def initialize(epsilon: 0.001, confidence: 0.99)
        @width = (Math::E / epsilon).ceil
        @depth = Math.log(1.0 / (1.0 - confidence)).ceil
        @table = Array.new(@depth) { Array.new(@width, 0) }
        @mutex = Mutex.new
      end

      def add(element, count = 1)
        key = element.to_s
        indexes = hash_indexes(key)

        @mutex.synchronize do
          indexes.each_with_index do |col, row|
            @table[row][col] += count
          end
        end
        true
      end

      def estimate(element)
        key = element.to_s
        indexes = hash_indexes(key)

        @mutex.synchronize do
          indexes.each_with_index.map { |col, row| @table[row][col] }.min
        end
      end

      def clear
        @mutex.synchronize do
          @table.each { |row| row.fill(0) }
        end
        true
      end

      def stats
        {
          type: :count_min_sketch,
          width: @width,
          depth: @depth,
          memory_cells: @width * @depth
        }
      end

      private

      def hash_indexes(key)
        h1 = Zlib.crc32(key)
        h2 = Digest::SHA256.hexdigest(key)[0..7].hex

        Array.new(@depth) do |i|
          (h1 + i * h2) % @width
        end
      end
    end
  end
end
