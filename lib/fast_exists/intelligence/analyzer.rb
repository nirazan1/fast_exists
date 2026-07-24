# frozen_string_literal: true

module FastExists
  module Intelligence
    class Analyzer
      PREFERRED_CANDIDATES = %w[
        email username slug sku phone uuid api_key external_id oauth_id token session_id identifier code
      ].freeze

      EXCLUDED_TYPES = [:json, :jsonb, :text, :binary, :boolean].freeze

      def self.analyze(target = nil, attribute = nil, models: nil)
        new.analyze(target, attribute, models: models)
      end

      def analyze(target = nil, attribute = nil, models: nil)
        target_models = determine_models(target, models)
        model_results = {}

        target_models.each do |klass|
          next unless klass.respond_to?(:table_exists?) && klass.table_exists?
          model_analysis = analyze_model(klass, attribute)
          model_results[klass.name] = model_analysis if model_analysis[:candidates].any? || target
        end

        {
          application: collect_app_info,
          models: model_results,
          overall_suitability_score: calculate_overall_score(model_results)
        }
      end

      private

      def determine_models(target, models)
        if target.is_a?(Class) && target < ActiveRecord::Base
          [target]
        elsif models.is_a?(Array)
          models.compact
        elsif defined?(ActiveRecord::Base)
          ActiveRecord::Base.descendants.reject(&:abstract_class?)
        else
          []
        end
      end

      def analyze_model(klass, target_attr = nil)
        row_count = klass.count rescue 0
        indexes = klass.connection.indexes(klass.table_name) rescue []

        candidates = []
        columns = klass.columns rescue []

        columns.each do |col|
          attr_name = col.name
          next if target_attr && attr_name != target_attr.to_s
          next if EXCLUDED_TYPES.include?(col.type)
          next if col.name == klass.primary_key

          # Check indexes
          indexed = indexes.any? { |idx| idx.columns.include?(attr_name) }
          is_unique = indexes.any? { |idx| idx.unique && idx.columns.include?(attr_name) }
          is_preferred = PREFERRED_CANDIDATES.include?(attr_name)

          next unless indexed || is_preferred

          suitability = calculate_candidate_suitability(col, indexed, is_unique, is_preferred, row_count)

          candidates << {
            attribute: attr_name,
            column_type: col.type,
            indexed: indexed,
            unique: is_unique,
            suitability_score: suitability,
            expected_queries_saved_per_day: (row_count * 0.15).ceil,
            estimated_memory_bytes: estimate_memory(row_count)
          }
        end

        candidates.sort_by! { |c| -c[:suitability_score] }

        {
          model: klass.name,
          table_name: klass.table_name,
          row_count: row_count,
          candidates: candidates,
          recommended_backend: row_count > 500_000 ? :redis : :memory
        }
      end

      def calculate_candidate_suitability(col, indexed, unique, preferred, row_count)
        score = 50
        score += 25 if unique
        score += 15 if indexed
        score += 10 if preferred
        score = [score, 100].min
        score
      end

      def estimate_memory(n)
        m = (-(n * Math.log(0.001)) / (Math.log(2)**2)).ceil rescue 143_775
        (m / 8.0).ceil
      end

      def calculate_overall_score(results)
        return 0 if results.empty?
        all_candidates = results.values.flat_map { |r| r[:candidates] }
        return 0 if all_candidates.empty?
        (all_candidates.sum { |c| c[:suitability_score] }.to_f / all_candidates.size).round
      end

      def collect_app_info
        {
          ruby_version: RUBY_VERSION,
          rails_version: defined?(Rails) && Rails.respond_to?(:version) ? Rails.version : "N/A",
          database: defined?(ActiveRecord::Base) ? (ActiveRecord::Base.connection_db_config.adapter rescue "sqlite3") : "N/A"
        }
      end
    end
  end
end
