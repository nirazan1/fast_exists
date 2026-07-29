# ⚡ FastExists

> **Ultra-Fast Existence Checks in Ruby on Rails Using Probabilistic Data Structures**

[![CI](https://github.com/nirazan1/fast_exists/actions/workflows/ci.yml/badge.svg)](https://github.com/nirazan1/fast_exists/actions)
[![Gem Version](https://img.shields.io/badge/version-v1.0.1-blue.svg)](https://github.com/nirazan1/fast_exists/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**FastExists** is a production-ready Ruby gem that drastically reduces unnecessary database queries in Ruby on Rails applications by evaluating existence checks against ultra-fast, thread-safe probabilistic data structures (Bloom Filters, Scalable Bloom Filters, Cuckoo Filters, HyperLogLog) while **keeping the database as the single source of truth**.

---

## 🎯 Target Use Cases

High-volume Rails applications handle millions or billions of existence checks where **most lookups are negative** (the record does NOT exist in the database). Hitting PostgreSQL/MySQL for every negative check wastes database IOPS, CPU cycles, and connection pool slots.

`fast_exists` eliminates unnecessary database reads in scenarios such as:

- 👤 **Username & Email Availability Checks**: Checking if an email or username is available as a user types during signup forms.
- 📦 **E-Commerce SKU & Catalog Lookups**: Validating if a product SKU exists before initiating complex inventory or cart processing.
- 🏷️ **URL Slug Reservation**: Instantly verifying if a vanity URL slug is taken.
- 🔑 **API Key & Token Authentication**: Ruling out invalid or non-existent API tokens before executing database queries.
- 📥 **High-Volume CSV/JSON Data Imports**: Deduplicating customer or product records when importing millions of rows.
- 🔁 **Webhook & Event Idempotency**: Checking if a Stripe or third-party webhook event ID has been processed previously.
- 🛡️ **Session & Fraud Prevention**: Checking if a device fingerprint or IP session has been flagged before.

---

## 🌟 Key Features

- **Rails-First DSL**: Clean macro integration for any ActiveRecord model (`fast_exists :email, :username`).
- **Database Primacy**: Zero false negatives! The database is always queried for affirmative checks.
- **Adaptive Multi-Tenant Management**: Enterprise allocation strategy (`:adaptive`) reducing Redis key count by 99% and memory by 78% for multi-tenant SaaS apps.
- **Swappable Backends**: In-Memory (`:memory`), Redis (`:redis`), RedisBloom (`:redis_bloom`), Persistent File (`:file`), and Null (`:null`).
- **Thread-Safe**: Fully synchronized bit array mutations for multi-threaded Rails servers (Puma, Falcon).
- **Auto-Sync**: Automatic `after_commit` hooks keep filters updated across record creations.
- **Performance Intelligence Suite**: Built-in operational health checks (`health!`), model reflection (`analyze!`), architectural auditing (`audit!`), code snippet generation (`doctor!`), and multi-format reporting (`report!`).
- **Instrumentation**: ActiveSupport::Notifications, Prometheus metrics, and OpenTelemetry tracing.
- **Mountable Engine Dashboard**: Real-time stats dashboard accessible at `/fast_exists`.

---

## 📦 Installation

Add `fast_exists` (latest version **v1.0.1**) to your Gemfile:

```ruby
# From RubyGems
gem "fast_exists", "~> 1.0.1"

# Or directly from GitHub repository
gem "fast_exists", git: "https://github.com/nirazan1/fast_exists.git", tag: "v1.0.1"
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

# Availability check (inverse helper)
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

## ⚙️ Backend Configuration Guide

`FastExists` provides a flexible configuration DSL in `config/initializers/fast_exists.rb`. Backends are swappable without changing application code.

### Global Configuration Example

```ruby
# config/initializers/fast_exists.rb
FastExists.configure do |config|
  # Default backend: :memory, :redis, :redis_bloom, :file, :null
  config.backend = :redis

  # Target false positive rate (0.1% default)
  config.false_positive_rate = 0.001

  # Expected elements per Bloom filter
  config.expected_elements = 10_000_000

  # Auto-synchronize on record commit
  config.auto_sync = true

  # ActiveSupport::Notifications instrumentation
  config.instrumentation = true

  # Redis connection configuration (single client or ConnectionPool)
  config.redis = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))
end
```

---

### Supported Backends & Setup

#### 1. In-Memory Backend (`:memory`)
- **Use Case**: Single-server setups, development, or testing.
- **Details**: Thread-safe in-memory bit array with zero external service dependencies.
```ruby
FastExists.configure do |config|
  config.backend = :memory
  config.expected_elements = 1_000_000
end
```

#### 2. Redis Backend (`:redis`)
- **Use Case**: Multi-server, multi-process production Rails apps (Puma workers, Kubernetes).
- **Details**: Uses Redis string bitfield operations (`SETBIT`/`GETBIT`).
```ruby
FastExists.configure do |config|
  config.backend = :redis
  config.redis = ConnectionPool.new(size: 25, timeout: 5) do
    Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))
  end
end
```

#### 3. RedisBloom Backend (`:redis_bloom`)
- **Use Case**: High-scale enterprise deployments with Redis Enterprise or Redis Stack modules.
- **Details**: Delegates directly to native C-level RedisBloom commands (`BF.ADD`, `BF.EXISTS`, `BF.RESERVE`).
```ruby
FastExists.configure do |config|
  config.backend = :redis_bloom
  config.redis = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))
end
```

#### 4. File-Backed Backend (`:file`)
- **Use Case**: Single-server production apps needing filter persistence across process restarts.
- **Details**: Atomic JSON/binary state dumps saved to disk.
```ruby
FastExists.configure do |config|
  config.backend = :file
  config.file_path = "storage/fast_exists_filters.bloom"
end
```

#### 5. Null Pass-Through Backend (`:null`)
- **Use Case**: Staging or test environments where filters are bypassed.
- **Details**: Always returns `true` (Maybe Present), safely forcing all queries to hit the database directly.
```ruby
FastExists.configure do |config|
  config.backend = :null
end
```

---

### Model-Level & Multi-Tenant Overrides

You can override backends, false positive targets, and namespaces per model:

```ruby
class Customer < ApplicationRecord
  # Custom backend & target rate
  fast_exists :email,
              backend: :redis_bloom,
              false_positive_rate: 0.0001,
              expected_elements: 50_000_000

  # Multi-tenant isolation (separate filter per account)
  fast_exists :sku,
              namespace: ->(record_or_ctx) { Current.account&.id || "global" }
end
```

---

## 📊 Statistics & Mountable Dashboard

Mount the dashboard in `config/routes.rb`:

```ruby
mount FastExists::Engine => "/fast_exists"
```

Fetch runtime statistics programmatically:

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

## 📖 Performance Intelligence Suite & Documentation

- 🧠 **[Performance Intelligence Suite Guide](docs/PERFORMANCE_INTELLIGENCE.md)** (`health!`, `analyze!`, `audit!`, `doctor!`, `report!`)
- 🏛️ [Architecture Guide](docs/ARCHITECTURE.md)
- 🚀 [Deployment Guide](docs/DEPLOYMENT.md)
- 🔴 [Redis & RedisBloom Guide](docs/REDIS_GUIDE.md)
- 📏 [Memory Sizing Guide](docs/MEMORY_SIZING.md)
- ⚡ [Performance & Benchmarks](docs/BENCHMARKS.md)
- ❓ [FAQ & Troubleshooting](docs/FAQ.md)

---

## 📄 License

The gem is available as open source under the terms of the [MIT License](LICENSE.txt).
