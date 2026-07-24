# frozen_string_literal: true

module FastExists
  module Backends
    class Null < Base
      def add(_key)
        true
      end

      def contains?(_key)
        true # Always maybe present -> forces DB check (safe fallback)
      end

      def clear
        true
      end

      def count
        0
      end

      def capacity
        @expected_elements
      end

      def stats
        { backend: :null, capacity: capacity, count: 0, status: :disabled }
      end
    end
  end
end
