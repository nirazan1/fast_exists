# frozen_string_literal: true

require "csv"

module FastExists
  module Intelligence
    module Report
      class Csv
        def self.render(data, comparison: nil)
          CSV.generate(headers: true) do |csv|
            csv << ["Category", "Metric / Location", "Value / Message", "Status / Severity"]

            csv << ["Environment", "Ruby Version", data.environment[:ruby_version], "info"]
            csv << ["Environment", "Rails Version", data.environment[:rails_version], "info"]
            csv << ["Environment", "Backend", data.environment[:backend], "info"]

            csv << ["Health", "Overall Status", data.health[:overall_status], data.health[:overall_status]]
            data.health[:checks].each do |c|
              csv << ["Health Check", c[:name], c[:message], c[:status]]
            end

            csv << ["Stats", "Queries Avoided", data.stats[:queries_avoided], "info"]
            csv << ["Stats", "Database Lookups", data.stats[:database_lookups], "info"]
            csv << ["Stats", "Bloom Hits", data.stats[:bloom_hits], "info"]
            csv << ["Stats", "False Positives", data.stats[:false_positives], "info"]
            csv << ["Stats", "Hit Ratio", "#{(data.stats[:hit_ratio] * 100).round(1)}%", "info"]

            csv << ["Audit", "Score", data.audit[:audit_score], data.audit[:grade]]
            data.audit[:findings].each do |f|
              csv << ["Audit Finding", f[:location], f[:problem], f[:severity]]
            end
          end
        end
      end
    end
  end
end
