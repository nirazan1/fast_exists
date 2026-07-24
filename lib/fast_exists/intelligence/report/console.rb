# frozen_string_literal: true

module FastExists
  module Intelligence
    module Report
      class Console
        def self.render(data, comparison: nil)
          lines = []
          lines << "=========================================================="
          lines << "⚡ FAST_EXISTS PERFORMANCE & ARCHITECTURE REPORT"
          lines << "=========================================================="
          lines << "Timestamp: #{data.timestamp}"
          lines << "Environment: Ruby #{data.environment[:ruby_version]} | Rails #{data.environment[:rails_version]} | Adapter #{data.environment[:database_adapter]}"
          lines << "Active Backend: #{data.environment[:backend]}"
          lines << ""
          lines << "1. OPERATIONAL HEALTH: #{data.health[:overall_status].to_s.upcase}"
          data.health[:checks].each do |check|
            mark = check[:status] == :pass ? "✓" : "⚠"
            lines << "   #{mark} #{check[:name]}: #{check[:message]}"
          end
          lines << ""
          lines << "2. ARCHITECTURAL AUDIT & GRADE"
          lines << "   Audit Score: #{data.audit[:audit_score]}/100 (Grade: #{data.audit[:grade]})"
          data.audit[:findings].each do |f|
            lines << "   - [#{f[:severity].to_s.upcase}] #{f[:location]}: #{f[:problem]}"
          end
          lines << ""
          lines << "3. RUNTIME STATISTICS"
          lines << "   Queries Avoided:  #{data.stats[:queries_avoided]}"
          lines << "   Database Lookups: #{data.stats[:database_lookups]}"
          lines << "   Bloom Hits:       #{data.stats[:bloom_hits]}"
          lines << "   Bloom Misses:     #{data.stats[:bloom_misses]}"
          lines << "   Hit Ratio:        #{(data.stats[:hit_ratio] * 100).round(1)}%"
          lines << "=========================================================="
          lines.join("\n")
        end
      end
    end
  end
end
