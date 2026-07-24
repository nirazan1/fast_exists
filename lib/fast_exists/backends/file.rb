# frozen_string_literal: true

require "fileutils"
require "json"

module FastExists
  module Backends
    class File < Base
      attr_reader :file_path, :filter

      def initialize(options = {})
        super
        @file_path = options[:file_path] || FastExists.configuration.file_path || "tmp/fast_exists_#{@options[:namespace] || 'default'}.bloom"
        @filter = FastExists::Bloom::Filter.new(
          expected_elements: @expected_elements,
          false_positive_rate: @false_positive_rate
        )
        load if ::File.exist?(@file_path)
      end

      def add(key)
        res = @filter.add(key)
        save
        res
      end

      def contains?(key)
        @filter.contains?(key)
      end

      def clear
        res = @filter.clear
        ::File.delete(@file_path) if ::File.exist?(@file_path)
        res
      end

      def count
        @filter.count
      end

      def capacity
        @filter.capacity
      end

      def save
        FileUtils.mkdir_p(::File.dirname(@file_path))
        dump = @filter.dump
        temp_file = "#{@file_path}.tmp"
        ::File.binwrite(temp_file, JSON.generate(dump))
        ::File.rename(temp_file, @file_path)
        true
      rescue => e
        raise BackendError, "Failed to save file backend: #{e.message}"
      end

      def load
        return false unless ::File.exist?(@file_path)
        data = JSON.parse(::File.binread(@file_path), symbolize_names: true)
        @filter = FastExists::Bloom::Filter.load(data)
        true
      rescue => e
        raise BackendError, "Failed to load file backend: #{e.message}"
      end

      def stats
        @filter.stats.merge(backend: :file, file_path: @file_path)
      end
    end
  end
end
