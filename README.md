# ⚡ FastExists

> **Ultra-Fast Existence Checks in Ruby on Rails Using Probabilistic Data Structures**

[![CI](https://github.com/fastexists/fast_exists/actions/workflows/ci.yml/badge.svg)](https://github.com/fastexists/fast_exists/actions)
[![Gem Version](https://badge.fury.io/rb/fast_exists.svg)](https://badge.fury.io/rb/fast_exists)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**FastExists** is a production-ready Ruby gem that drastically reduces unnecessary database queries in Ruby on Rails applications by evaluating existence checks against ultra-fast, thread-safe probabilistic data structures (Bloom Filters, Scalable Bloom Filters, Cuckoo Filters, HyperLogLog) while **keeping the database as the single source of truth**.

---

## 🌟 Key Features

- **Rails-First DSL**: Clean macro integration for any ActiveRecord model (`fast_exists :email, :username`).
- **Database Primacy**: Zero false negatives! The database is always queried for affirmative checks.
- **Swappable Backends**: In-Memory, Redis, RedisBloom, Persistent File, and Null backends.
- **Thread-Safe**: Fully synchronized bit array mutations for multi-threaded Rails servers (Puma, Falcon).
- **Auto-Sync**: Automatic `after_commit` hooks keep filters updated across record creations.
- **Built-in Instrumentation**: ActiveSupport::Notifications, Prometheus metrics, and OpenTelemetry tracing.
- **AI Advisor**: Intelligent usage analyzer recommending optimal bit array sizing, hash counts, and backends.
- **Mountable Engine Dashboard**: Real-time stats dashboard accessible at `/fast_exists`.

---

## 📦 Installation

Add `fast_exists` to your Gemfile:

```ruby
gem "fast_exists"
```

Then run:

```bash
bundle install
rails generate fast_exists:install
```

---

## 🚀 Quick Start

### 1. Configure Model

```ruby
class User < ApplicationRecord
  fast_exists :email
  fast_exists :username
end
```

### 2. Perform Ultra-Fast Existence Checks

```ruby
# Fast check (0 DB queries if negative!)
User.email_exists?("john@example.com")
User.username_exists?("john")

# Availability check
User.email_available?("john@example.com")

# Generic helpers
User.fast_exists?(:email, "john@example.com")
User.fast_available?(:email, "john@example.com")
```

### 3. Rebuild Filters

```ruby
User.rebuild_fast_exists!
```

---

## ⚙️ Advanced Configuration

```ruby
# config/initializers/fast_exists.rb
FastExists.configure do |config|
  config.backend = :redis
  config.false_positive_rate = 0.001
  config.expected_elements = 10_000_000
  config.auto_sync = true
  config.redis = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))
end
```

---

## 📊 Statistics & Dashboard

Mount the dashboard in your `config/routes.rb`:

```ruby
mount FastExists::Engine => "/fast_exists"
```

Fetch runtime statistics in Ruby:

```ruby
FastExists.stats
# => {
#   queries_avoided: 142500,
#   database_lookups: 1200,
#   bloom_hits: 1200,
#   false_positives: 2,
#   hit_ratio: 0.0084,
#   miss_ratio: 0.9916
# }
```

---

## 📖 Documentation

- [Architecture Guide](docs/ARCHITECTURE.md)
- [Deployment Guide](docs/DEPLOYMENT.md)
- [Redis & RedisBloom Guide](docs/REDIS_GUIDE.md)
- [Memory Sizing Guide](docs/MEMORY_SIZING.md)
- [Performance & Benchmarks](docs/BENCHMARKS.md)
- [FAQ & Troubleshooting](docs/FAQ.md)

---

## 📄 License

The gem is available as open source under the terms of the [MIT License](LICENSE.txt).
