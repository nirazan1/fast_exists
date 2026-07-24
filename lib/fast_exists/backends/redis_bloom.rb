# frozen_string_literal: true

module FastExists
  module Backends
    class RedisBloom < Base
      attr_reader :filter_key

      def initialize(options = {})
        super
        @redis = options[:redis] || FastExists.configuration.redis
        @filter_key = options[:namespace] ? "fast_exists:bf:#{options[:namespace]}" : "fast_exists:bf:default"
        ensure_filter_reserved
      end

      def add(element)
        execute_redis do |client|
          client.call(["BF.ADD", @filter_key, element.to_s]) == 1
        end
      end

      def contains?(element)
        execute_redis do |client|
          client.call(["BF.EXISTS", @filter_key, element.to_s]) == 1
        end
      end

      def clear
        execute_redis do |client|
          client.del(@filter_key)
        end
        ensure_filter_reserved
        true
      end

      def count
        info = stats
        info[:inserted_items] || 0
      end

      def capacity
        @expected_elements
      end

      def stats
        execute_redis do |client|
          raw_info = client.call(["BF.INFO", @filter_key]) rescue []
          info_hash = Hash[*raw_info] rescue {}
          {
            backend: :redis_bloom,
            filter_key: @filter_key,
            expected_elements: @expected_elements,
            false_positive_rate: @false_positive_rate,
            inserted_items: info_hash["Number of items inserted"] || 0,
            capacity: info_hash["Capacity"] || @expected_elements,
            bytes: info_hash["Size"] || 0
          }
        end
      end

      private

      def ensure_filter_reserved
        execute_redis do |client|
          client.call(["BF.RESERVE", @filter_key, @false_positive_rate, @expected_elements])
        end
      rescue => e
        # Ignore if filter already exists
      end

      def execute_redis
        if @redis.respond_to?(:with)
          @redis.with { |conn| yield conn }
        elsif @redis
          yield @redis
        elsif defined?(::Redis) && ::Redis.respond_to?(:current)
          yield ::Redis.current
        else
          raise BackendError, "Redis client not configured. Set config.redis = Redis.new"
        end
      end
    end
  end
end
