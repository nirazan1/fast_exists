# frozen_string_literal: true

require "zlib"
require "digest"

module FastExists
  module Backends
    class Redis < Base
      attr_reader :key_prefix, :bit_size, :hash_count

      def initialize(options = {})
        super
        @redis = options[:redis] || FastExists.configuration.redis
        @key_prefix = options[:namespace] ? "fast_exists:#{options[:namespace]}" : "fast_exists:default"

        # Bloom filter parameters calculation
        n = @expected_elements
        p = @false_positive_rate
        @bit_size = (-(n * Math.log(p)) / (Math.log(2)**2)).ceil
        @hash_count = [((@bit_size.to_f / n) * Math.log(2)).round, 1].max
        @count_key = "#{@key_prefix}:count"
        @bit_key = "#{@key_prefix}:bits"
      end

      def add(element)
        indexes = hash_indexes(element.to_s)
        execute_redis do |client|
          indexes.each do |idx|
            client.setbit(@bit_key, idx, 1)
          end
          client.incr(@count_key)
        end
        true
      end

      def contains?(element)
        indexes = hash_indexes(element.to_s)
        execute_redis do |client|
          indexes.all? do |idx|
            client.getbit(@bit_key, idx) == 1
          end
        end
      end

      def clear
        execute_redis do |client|
          client.del(@bit_key, @count_key)
        end
        true
      end

      def count
        execute_redis do |client|
          (client.get(@count_key) || 0).to_i
        end
      end

      def capacity
        @expected_elements
      end

      def stats
        {
          backend: :redis,
          bit_key: @bit_key,
          expected_elements: @expected_elements,
          false_positive_rate: @false_positive_rate,
          inserted_items: count,
          bit_size: @bit_size,
          hash_count: @hash_count
        }
      end

      private

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
