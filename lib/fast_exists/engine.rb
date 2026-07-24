# frozen_string_literal: true

if defined?(Rails::Engine)
  module FastExists
    class Engine < ::Rails::Engine
      isolate_namespace FastExists

      routes.draw do
        root to: "dashboard#index"
        get "/stats", to: "dashboard#stats"
      end
    end

    class DashboardController < ActionController::Base
      def index
        @stats = FastExists.stats
        @advisor = FastExists::Optimizer::AiAdvisor.analyze
        render html: dashboard_html.html_safe
      end

      def stats
        render json: FastExists.stats
      end

      private

      def dashboard_html
        <<-HTML
        <!DOCTYPE html>
        <html>
        <head>
          <title>FastExists Dashboard</title>
          <style>
            body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #0f172a; color: #f8fafc; margin: 0; padding: 2rem; }
            h1 { color: #38bdf8; font-size: 2.25rem; font-weight: 700; margin-bottom: 0.5rem; }
            p.subtitle { color: #94a3b8; font-size: 1rem; margin-bottom: 2rem; }
            .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 1.5rem; margin-bottom: 2rem; }
            .card { background: #1e293b; border-radius: 0.75rem; padding: 1.5rem; border: 1px solid #334155; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1); }
            .card-title { color: #94a3b8; font-size: 0.875rem; font-weight: 600; text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 0.5rem; }
            .card-val { font-size: 2rem; font-weight: 700; color: #38bdf8; }
            .advice-card { background: #1e293b; border-left: 4px solid #38bdf8; padding: 1.5rem; border-radius: 0.5rem; margin-top: 2rem; }
            .advice-title { font-weight: 700; font-size: 1.1rem; color: #e2e8f0; margin-bottom: 0.5rem; }
            .advice-text { color: #cbd5e1; line-height: 1.6; }
          </style>
        </head>
        <body>
          <h1>⚡ FastExists Dashboard</h1>
          <p class="subtitle">Real-time Probabilistic Filter Performance & Statistics</p>
          <div class="grid">
            <div class="card"><div class="card-title">Queries Avoided</div><div class="card-val">#{@stats[:queries_avoided]}</div></div>
            <div class="card"><div class="card-title">DB Lookups</div><div class="card-val">#{@stats[:database_lookups]}</div></div>
            <div class="card"><div class="card-title">Bloom Hits</div><div class="card-val">#{@stats[:bloom_hits]}</div></div>
            <div class="card"><div class="card-title">False Positives</div><div class="card-val">#{@stats[:false_positives]}</div></div>
            <div class="card"><div class="card-title">Hit Ratio</div><div class="card-val">#{(@stats[:hit_ratio] * 100).round(1)}%</div></div>
          </div>
          <div class="advice-card">
            <div class="advice-title">🤖 AI Optimizer Recommendation</div>
            <div class="advice-text">#{@advisor[:recommendations][:advice]}</div>
          </div>
        </body>
        </html>
        HTML
      end
    end
  end
end
