# Redis & RedisBloom Integration Guide

## Backend Selection

- `:redis`: Uses standard Redis bitfield & string commands (`SETBIT`/`GETBIT`). Compatible with all standard Redis instances (AWS ElastiCache, MemoryDB, Azure Cache for Redis).
- `:redis_bloom`: Utilizes native `RedisBloom` module (`BF.ADD`, `BF.EXISTS`, `BF.RESERVE`). Provides maximum C-level performance on Redis Enterprise or Stack.

## Configuration Example

```ruby
FastExists.configure do |config|
  config.backend = :redis
  config.redis = ConnectionPool.new(size: 20) { Redis.new(url: ENV["REDIS_URL"]) }
end
```
