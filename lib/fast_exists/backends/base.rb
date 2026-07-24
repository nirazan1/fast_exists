# frozen_string_literal: true

module FastExists
  module Backends
    class Base
      attr_reader :options

      def initialize(options = {})
        @options = options
        @expected_elements = options[:expected_elements] || FastExists.configuration.expected_elements
        @false_positive_rate = options[:false_positive_rate] || FastExists.configuration.false_positive_rate
      end

      def add(key)
        raise NotImplementedError, "#{self.class.name}#add is not implemented"
      end

      def contains?(key)
        raise NotImplementedError, "#{self.class.name}#contains? is not implemented"
      end

      def clear
        raise NotImplementedError, "#{self.class.name}#clear is not implemented"
      end

      def save
        true
      end

      def load
        true
      end

      def count
        0
      end

      def capacity
        @expected_elements
      end

      def stats
        {
          backend: self.class.name,
          capacity: capacity,
          count: count
        }
      end

      def rebuild(enumerable)
        clear
        enumerable.each do |item|
          add(item)
        end
        save
        true
      end
    end
  end
end
