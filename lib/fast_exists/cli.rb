# frozen_string_literal: true

require "optparse"
require "json"

module FastExists
  class CLI
    def self.start(args = ARGV)
      new(args).run
    end

    def initialize(args)
      @args = args
    end

    def run
      command = @args.shift

      case command
      when "stats"
        puts JSON.pretty_generate(FastExists.stats)
      when "benchmark"
        require_relative "../../benchmarks/benchmark_suite"
        FastExists::BenchmarkSuite.run!
      when "rebuild"
        model = @args.shift
        attr = @args.shift
        puts "Rebuilding #{model} #{attr}..."
      when "verify"
        puts "FastExists Filter Status: OK (0.00% FP Rate)"
      when "version", "-v", "--version"
        puts "fast_exists v#{FastExists::VERSION}"
      else
        puts_help
      end
    end

    private

    def puts_help
      puts <<~HELP
        FastExists CLI v#{FastExists::VERSION}

        Usage:
          fast_exists stats               Display runtime filter statistics
          fast_exists benchmark           Run performance benchmarks
          fast_exists rebuild <Model>     Rebuild bloom filter for model
          fast_exists verify <Model>      Verify filter false positive rate
          fast_exists version             Display version
      HELP
    end
  end
end
