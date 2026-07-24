# Production Deployment Guide

## Pre-Deployment Checklist

1. **Initializer Configuration**: Ensure `config/initializers/fast_exists.rb` defines the appropriate backend (`:redis` or `:redis_bloom` for multi-server environments).
2. **Warm Filters**: Run filter pre-warming during deployment build steps:
   ```bash
   bundle exec rake fast_exists:rebuild[User,email]
   ```
3. **Connection Pooling**: Configure Redis connection pooling if using Puma with multiple threads per worker.
4. **Monitoring**: Mount `FastExists::Engine` or scrape `/metrics` using Prometheus exporter.
