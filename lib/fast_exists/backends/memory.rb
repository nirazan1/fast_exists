# frozen_string_literal: true

module FastExists
  module Backends
    class Memory < Base
      attr_reader :filter

      def initialize(options = {})
        super
        @filter = FastExists::Bloom::Filter.new(
          expected_elements: @expected_elements,
          false_positive_rate: @false_positive_rate
        )
      end

      def add(key)
        @filter.add(key)
      end

      def contains?(key)
        @filter.contains?(key)
      end

      def clear
        @filter.clear
      end

      def count
        @filter.count
      end

      def capacity
        @filter.capacity
      end

      def stats
        @filter.stats.merge(backend: :memory)
      end
    end
  end
end
