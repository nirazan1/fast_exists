# frozen_string_literal: true

module FastExists
  module Bloom
    class Scalable
      attr_reader :initial_capacity, :false_positive_rate, :growth_factor, :tightening_ratio

      def initialize(initial_capacity: 10_000, false_positive_rate: 0.001, growth_factor: 2, tightening_ratio: 0.8)
        @initial_capacity = initial_capacity
        @false_positive_rate = false_positive_rate
        @growth_factor = growth_factor
        @tightening_ratio = tightening_ratio
        @mutex = Mutex.new

        @filters = []
        add_filter
      end

      def add(element)
        @mutex.synchronize do
          current_filter = @filters.last
          if current_filter.count >= current_filter.capacity
            add_filter
            current_filter = @filters.last
          end
          current_filter.add(element)
        end
        true
      end

      def contains?(element)
        @mutex.synchronize do
          @filters.any? { |filter| filter.contains?(element) }
        end
      end

      def clear
        @mutex.synchronize do
          @filters.clear
          add_filter
        end
        true
      end

      def count
        @mutex.synchronize do
          @filters.sum(&:count)
        end
      end

      def capacity
        @mutex.synchronize do
          @filters.sum(&:capacity)
        end
      end

      def stats
        @mutex.synchronize do
          {
            type: :scalable_bloom,
            filter_count: @filters.size,
            inserted_items: count,
            capacity: capacity,
            memory_usage_bytes: @filters.sum(&:memory_usage_bytes)
          }
        end
      end

      private

      def add_filter
        idx = @filters.size
        cap = (@initial_capacity * (@growth_factor**idx)).round
        fp = @false_positive_rate * (@tightening_ratio**idx)
        @filters << FastExists::Bloom::Filter.new(expected_elements: cap, false_positive_rate: fp)
      end
    end
  end
end
