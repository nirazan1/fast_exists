# frozen_string_literal: true

require "zlib"
require "digest"

module FastExists
  module Probabilistic
    class HyperLogLog
      attr_reader :p, :m

      def initialize(p: 14)
        raise InvalidArgumentError, "p must be between 4 and 16" if p < 4 || p > 16

        @p = p
        @m = 1 << p
        @registers = Array.new(@m, 0)
        @alpha = calculate_alpha(@m)
        @mutex = Mutex.new
      end

      def add(element)
        hash = Digest::SHA256.hexdigest(element.to_s)[0..15].hex
        idx = hash >> (64 - @p)
        w = hash & ((1 << (64 - @p)) - 1)
        rho = leading_zeros(w, 64 - @p) + 1

        @mutex.synchronize do
          @registers[idx] = [@registers[idx], rho].max
        end
        true
      end

      def count
        @mutex.synchronize do
          raw_estimate = @alpha * (@m**2) * (1.0 / @registers.sum { |r| 2.0**(-r) })

          if raw_estimate <= 2.5 * @m
            zeros = @registers.count(0)
            zeros > 0 ? @m * Math.log(@m.to_f / zeros) : raw_estimate
          else
            raw_estimate
          end.round
        end
      end

      def clear
        @mutex.synchronize do
          @registers.fill(0)
        end
        true
      end

      def stats
        {
          type: :hyper_log_log,
          registers: @m,
          precision_p: @p,
          estimated_cardinality: count
        }
      end

      private

      def leading_zeros(val, bit_len)
        return bit_len if val == 0
        clz = 0
        (bit_len - 1).downto(0) do |bit|
          break if (val & (1 << bit)) != 0
          clz += 1
        end
        clz
      end

      def calculate_alpha(m)
        case m
        when 16 then 0.673
        when 32 then 0.697
        when 64 then 0.709
        else 0.7213 / (1.0 + 1.079 / m)
        end
      end
    end
  end
end
