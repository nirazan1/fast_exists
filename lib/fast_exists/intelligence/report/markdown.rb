# frozen_string_literal: true

module FastExists
  module Intelligence
    module Report
      class Markdown
        def self.render(data, comparison: nil)
          lines = []
          lines << "# ⚡ FastExists Performance & Architecture Report"
          lines << ""
          lines << "> **Generated**: `#{data.timestamp}`  "
          lines << "> **Environment**: Ruby #{data.environment[:ruby_version]} | Rails #{data.environment[:rails_version]} | DB: `#{data.environment[:database_adapter]}`  "
          lines << "> **Active Backend**: `#{data.environment[:backend]}`"
          lines << ""
          lines << "## Executive Summary"
          lines << "- **Health Status**: `#{data.health[:overall_status].to_s.upcase}`"
          lines << "- **Architecture Grade**: **#{data.audit[:grade]}** (#{data.audit[:audit_score]}/100)"
          lines << "- **Queries Avoided**: **#{data.stats[:queries_avoided]}**"
          lines << "- **Database Lookups**: #{data.stats[:database_lookups]}"
          lines << "- **Hit Ratio**: #{(data.stats[:hit_ratio] * 100).round(1)}%"
          lines << ""
          lines << "## Health Check Findings"
          data.health[:checks].each do |check|
            badge = check[:status] == :pass ? "✅" : "⚠️"
            lines << "- #{badge} **#{check[:name]}**: #{check[:message]}"
          end
          lines << ""
          lines << "## Audit & Optimizations"
          data.audit[:findings].each do |f|
            lines << "### [#{f[:severity].to_s.upcase}] #{f[:location]}"
            lines << "- **Problem**: #{f[:problem]}"
            lines << "- **Recommendation**: #{f[:recommendation]}"
            lines << "- **Impact**: #{f[:estimated_impact]}"
            lines << ""
          end
          lines.join("\n")
        end
      end
    end
  end
end
