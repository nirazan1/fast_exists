# frozen_string_literal: true

module FastExists
  module Intelligence
    module Report
      class Html
        def self.render(data, comparison: nil)
          hit_pct = (data.stats[:hit_ratio] * 100).round(1)
          miss_pct = (data.stats[:miss_ratio] * 100).round(1)

          <<-HTML
          <!DOCTYPE html>
          <html lang="en">
          <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>FastExists Performance & Architecture Report</title>
            <style>
              :root {
                --bg: #0f172a;
                --card-bg: #1e293b;
                --text: #f8fafc;
                --text-muted: #94a3b8;
                --accent: #38bdf8;
                --border: #334155;
                --pass: #22c55e;
                --warn: #eab308;
                --fail: #ef4444;
              }
              @media print {
                body { background: #fff !important; color: #000 !important; }
                .card { border: 1px solid #ccc !important; background: #fff !important; color: #000 !important; }
              }
              body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: var(--bg); color: var(--text); margin: 0; padding: 2.5rem; line-height: 1.5; }
              .header { border-bottom: 1px solid var(--border); padding-bottom: 1.5rem; margin-bottom: 2rem; }
              .title { font-size: 2.25rem; font-weight: 800; color: var(--accent); margin: 0 0 0.5rem 0; display: flex; align-items: center; gap: 0.5rem; }
              .subtitle { color: var(--text-muted); font-size: 1rem; margin: 0; }
              .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 1.5rem; margin-bottom: 2.5rem; }
              .card { background: var(--card-bg); border-radius: 0.75rem; padding: 1.5rem; border: 1px solid var(--border); box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1); }
              .card-title { color: var(--text-muted); font-size: 0.875rem; font-weight: 600; text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 0.5rem; }
              .card-val { font-size: 2.25rem; font-weight: 800; color: var(--accent); }
              .badge { display: inline-block; padding: 0.25rem 0.75rem; border-radius: 9999px; font-weight: 700; font-size: 0.875rem; text-transform: uppercase; }
              .badge-pass { background: rgba(34, 197, 94, 0.2); color: var(--pass); border: 1px solid var(--pass); }
              .badge-warn { background: rgba(234, 179, 8, 0.2); color: var(--warn); border: 1px solid var(--warn); }
              .badge-fail { background: rgba(239, 68, 68, 0.2); color: var(--fail); border: 1px solid var(--fail); }
              section { margin-bottom: 3rem; }
              h2 { font-size: 1.5rem; border-bottom: 1px solid var(--border); padding-bottom: 0.5rem; margin-bottom: 1.5rem; color: var(--text); }
              table { width: 100%; border-collapse: collapse; margin-top: 1rem; }
              th, td { padding: 0.75rem 1rem; text-align: left; border-bottom: 1px solid var(--border); }
              th { background: rgba(255,255,255,0.03); color: var(--text-muted); font-weight: 600; }
              pre { background: #090d16; padding: 1rem; border-radius: 0.5rem; overflow-x: auto; color: #a5f3fc; border: 1px solid var(--border); font-family: monospace; }
              .chart-bar { background: var(--border); height: 1.25rem; border-radius: 0.25rem; overflow: hidden; display: flex; margin-top: 0.5rem; }
              .chart-fill-hit { background: var(--accent); height: 100%; width: #{hit_pct}%; }
              .chart-fill-miss { background: #64748b; height: 100%; width: #{miss_pct}%; }
            </style>
          </head>
          <body>
            <div class="header">
              <h1 class="title">⚡ FastExists Performance Intelligence Report</h1>
              <p class="subtitle">Generated on #{data.timestamp} • Ruby #{data.environment[:ruby_version]} • Rails #{data.environment[:rails_version]} • Backend: <strong>#{data.environment[:backend]}</strong></p>
            </div>

            <div class="grid">
              <div class="card">
                <div class="card-title">Overall Health</div>
                <div class="card-val"><span class="badge badge-#{data.health[:overall_status] == :healthy ? 'pass' : 'warn'}">#{data.health[:overall_status]}</span></div>
              </div>
              <div class="card">
                <div class="card-title">Architecture Grade</div>
                <div class="card-val">#{data.audit[:grade]} <span style="font-size:1.1rem; color:var(--text-muted)">(&nbsp;#{data.audit[:audit_score]}/100&nbsp;)</span></div>
              </div>
              <div class="card">
                <div class="card-title">Queries Avoided</div>
                <div class="card-val">#{data.stats[:queries_avoided]}</div>
              </div>
              <div class="card">
                <div class="card-title">Database Lookups</div>
                <div class="card-val">#{data.stats[:database_lookups]}</div>
              </div>
            </div>

            <section>
              <h2>📊 Query Distribution & Bloom Hit Ratio</h2>
              <p>Hit Ratio: <strong>#{hit_pct}%</strong> | Miss Ratio: <strong>#{miss_pct}%</strong></p>
              <div class="chart-bar">
                <div class="chart-fill-hit" title="Hits: #{hit_pct}%"></div>
                <div class="chart-fill-miss" title="Avoided: #{miss_pct}%"></div>
              </div>
            </section>

            <section>
              <h2>🩺 Operational Health Checks</h2>
              <table>
                <thead>
                  <tr><th>Check Name</th><th>Status</th><th>Message</th></tr>
                </thead>
                <tbody>
                  #{data.health[:checks].map { |c| "<tr><td><strong>#{c[:name]}</strong></td><td><span class=\"badge badge-#{c[:status] == :pass ? 'pass' : 'warn'}\">#{c[:status]}</span></td><td>#{c[:message]}</td></tr>" }.join("\n")}
                </tbody>
              </table>
            </section>

            <section>
              <h2>🔍 Architectural Audit Findings</h2>
              #{data.audit[:findings].map { |f| "<div class=\"card\" style=\"margin-bottom:1rem;\"><div style=\"display:flex; justify-between; align-items:center;\"><strong>[#{f[:severity].to_s.upcase}] #{f[:location]}</strong></div><p style=\"color:var(--text-muted)\">#{f[:problem]}</p><p><strong>Recommendation:</strong> #{f[:recommendation]}</p></div>" }.join("\n")}
            </section>
          </body>
          </html>
          HTML
        end

        def self.render_doctor(recs)
          render(FastExists::Intelligence::DataModel.new)
        end
      end
    end
  end
end
