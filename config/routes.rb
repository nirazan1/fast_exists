# frozen_string_literal: true

FastExists::Engine.routes.draw do
  root to: "dashboard#index"
  get "/stats", to: "dashboard#stats"
end
