# frozen_string_literal: true

module FastExists
  module Intelligence
    class Doctor
      def self.diagnose(format = :console)
        fmt = format.is_a?(Hash) ? (format[:format] || :console) : format
        analysis = FastExists::Intelligence::Analyzer.analyze
        audit = FastExists::Intelligence::Auditor.audit
        health = FastExists::Intelligence::Health.check

        new(analysis, audit, health).render(format: fmt)
      end

      def initialize(analysis, audit, health)
        @analysis = analysis
        @audit = audit
        @health = health
      end

      def render(format = :console)
        fmt = format.is_a?(Hash) ? (format[:format] || :console) : format
        recommendations = build_recommendations

        case fmt.to_sym
        when :json
          JSON.pretty_generate(recommendations)
        when :yaml
          recommendations.transform_keys(&:to_s).to_yaml
        when :markdown
          to_markdown(recommendations)
        when :html
          to_html(recommendations)
        else
          to_console(recommendations)
        end
      end

      private

      def build_recommendations
        recs = []

        # 1. Model DSL Recommendations
        @analysis[:models].each do |model_name, data|
          candidates = data[:candidates].select { |c| c[:suitability_score] >= 75 }
          next if candidates.empty?

          attrs_str = candidates.map { |c| ":#{c[:attribute]}" }.join(", ")
          recs << {
            severity: :recommendation,
            title: "Add FastExists DSL to #{model_name}",
            problem: "Model #{model_name} has high-volume lookup candidate attributes (#{attrs_str}) without fast_exists filtering",
            why_it_matters: "Enabling fast_exists on #{model_name} will bypass unnecessary database lookups for missing records",
            recommended_solution: "Add `fast_exists #{attrs_str}` macro to #{model_name}",
            expected_improvement: "Saves ~#{(data[:row_count] * 0.15).ceil} database queries/day",
            code_snippet: <<~RUBY
              # app/models/#{model_name.underscore}.rb
              class #{model_name} < ApplicationRecord
                fast_exists #{attrs_str}
              end
            RUBY
          }
        end

        # 2. Missing Index Migration Snippets
        @audit[:findings].select { |f| f[:severity] == :critical }.each do |finding|
          loc = finding[:location]
          model_part, attr_part = loc.split("#")
          table_name = model_part.tableize rescue "table"

          recs << {
            severity: :warning,
            title: "Missing Database Index on #{loc}",
            problem: finding[:problem],
            why_it_matters: finding[:reason],
            recommended_solution: finding[:recommendation],
            expected_improvement: finding[:estimated_impact],
            code_snippet: <<~RUBY
              # db/migrate/#{Time.now.strftime('%Y%m%d%H%M%S')}_add_unique_index_to_#{table_name}_#{attr_part}.rb
              class AddUniqueIndexTo#{table_name.camelize}#{attr_part.camelize} < ActiveRecord::Migration[7.0]
                def change
                  add_index :#{table_name}, :#{attr_part}, unique: true
                end
              end
            RUBY
          }
        end

        # 3. Initializer Snippet
        recs << {
          severity: :info,
          title: "Recommended FastExists Initializer Configuration",
          problem: "Ensure production initializer is tuned for target element scale and backend",
          why_it_matters: "Proper expected_elements and backend settings optimize bit memory footprint and concurrency",
          recommended_solution: "Configure config/initializers/fast_exists.rb",
          expected_improvement: "Optimal memory usage and zero-overhead performance",
          code_snippet: <<~RUBY
            # config/initializers/fast_exists.rb
            FastExists.configure do |config|
              config.backend = :redis
              config.false_positive_rate = 0.001
              config.expected_elements = 5_000_000
              config.auto_sync = true
              config.instrumentation = true
            end
          RUBY
        }

        {
          health_status: @health[:overall_status],
          audit_score: @audit[:audit_score],
          grade: @audit[:grade],
          recommendations: recs
        }
      end

      def to_console(recs)
        lines = []
        lines << "=================================================="
        lines << "🩺 FastExists Doctor Diagnostic Report"
        lines << "   Overall Status: #{recs[:health_status].to_s.upcase} | Audit Score: #{recs[:audit_score]}/100 (Grade: #{recs[:grade]})"
        lines << "=================================================="
        lines << ""

        recs[:recommendations].each_with_index do |r, i|
          lines << "[#{i + 1}] #{r[:title]}"
          lines << "    Problem:              #{r[:problem]}"
          lines << "    Why It Matters:       #{r[:why_it_matters]}"
          lines << "    Recommended Solution: #{r[:recommended_solution]}"
          lines << "    Expected Improvement: #{r[:expected_improvement]}"
          lines << "    Code Snippet:"
          lines << r[:code_snippet].lines.map { |l| "      #{l}" }.join
          lines << "--------------------------------------------------"
        end

        lines.join("\n")
      end

      def to_markdown(recs)
        lines = []
        lines << "# 🩺 FastExists Doctor Diagnostic Report"
        lines << "**Overall Status**: `#{recs[:health_status].to_s.upcase}` | **Audit Score**: #{recs[:audit_score]}/100 (Grade: **#{recs[:grade]}**)"
        lines << ""

        recs[:recommendations].each do |r|
          lines << "### #{r[:title]}"
          lines << "- **Problem**: #{r[:problem]}"
          lines << "- **Why It Matters**: #{r[:why_it_matters]}"
          lines << "- **Recommended Solution**: #{r[:recommended_solution]}"
          lines << "- **Expected Improvement**: #{r[:expected_improvement]}"
          lines << ""
          lines << "```ruby"
          lines << r[:code_snippet].strip
          lines << "```"
          lines << ""
        end

        lines.join("\n")
      end

      def to_html(recs)
        # Delegated to FastExists::Intelligence::Report::Html
        FastExists::Intelligence::Report::Html.render_doctor(recs)
      end
    end
  end
end
