# frozen_string_literal: true

require "zlib"
require "digest"

module FastExists
  module Probabilistic
    class Cuckoo
      attr_reader :capacity, :bucket_size, :fingerprint_size, :count

      def initialize(capacity: 10_000, bucket_size: 4, max_kicks: 500)
        @capacity = capacity
        @bucket_size = bucket_size
        @max_kicks = max_kicks
        @num_buckets = (capacity.to_f / bucket_size).ceil
        @num_buckets = 1 if @num_buckets < 1
        @buckets = Array.new(@num_buckets) { [] }
        @count = 0
        @mutex = Mutex.new
      end

      def add(element)
        fp = fingerprint(element.to_s)
        i1 = hash_index(element.to_s)
        i2 = alt_index(i1, fp)

        @mutex.synchronize do
          if @buckets[i1].size < @bucket_size
            @buckets[i1] << fp
            @count += 1
            return true
          end

          if @buckets[i2].size < @bucket_size
            @buckets[i2] << fp
            @count += 1
            return true
          end

          # Kicking eviction loop
          curr_idx = rand(2) == 0 ? i1 : i2
          curr_fp = fp

          @max_kicks.times do
            evicted_fp = @buckets[curr_idx][rand(@buckets[curr_idx].size)]
            idx_in_bucket = @buckets[curr_idx].index(evicted_fp)
            @buckets[curr_idx][idx_in_bucket] = curr_fp

            curr_fp = evicted_fp
            curr_idx = alt_index(curr_idx, curr_fp)

            if @buckets[curr_idx].size < @bucket_size
              @buckets[curr_idx] << curr_fp
              @count += 1
              return true
            end
          end

          raise CapacityExceededError, "Cuckoo filter is full"
        end
      end

      def contains?(element)
        fp = fingerprint(element.to_s)
        i1 = hash_index(element.to_s)
        i2 = alt_index(i1, fp)

        @mutex.synchronize do
          @buckets[i1].include?(fp) || @buckets[i2].include?(fp)
        end
      end

      def delete(element)
        fp = fingerprint(element.to_s)
        i1 = hash_index(element.to_s)
        i2 = alt_index(i1, fp)

        @mutex.synchronize do
          if (idx = @buckets[i1].index(fp))
            @buckets[i1].delete_at(idx)
            @count -= 1
            return true
          elsif (idx = @buckets[i2].index(fp))
            @buckets[i2].delete_at(idx)
            @count -= 1
            return true
          end
        end
        false
      end

      def clear
        @mutex.synchronize do
          @buckets.each(&:clear)
          @count = 0
        end
        true
      end

      def stats
        @mutex.synchronize do
          {
            type: :cuckoo,
            inserted_items: @count,
            capacity: @capacity,
            buckets: @num_buckets,
            bucket_size: @bucket_size
          }
        end
      end

      private

      def fingerprint(key)
        Digest::MD5.digest(key)[0..1]
      end

      def hash_index(key)
        Zlib.crc32(key) % @num_buckets
      end

      def alt_index(index, fp)
        fp_hash = Zlib.crc32(fp)
        (index ^ fp_hash) % @num_buckets
      end
    end
  end
end
