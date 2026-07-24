# ADR 0002: Modular Backend Abstraction Architecture

## Context
Applications scale across different environments: from single-server development with local SQLite to multi-datacenter Kubernetes clusters backed by Redis clusters.

## Decision
Create a unified `FastExists::Backends::Base` interface with swappable backends (`Memory`, `Redis`, `RedisBloom`, `File`, `Null`) and a dynamic `Registry` plugin system.

## Consequences
- Application code (`User.email_exists?`) remains completely unchanged when swapping backends.
- Developers can register custom backends (e.g., DynamoDB, Memcached) via `FastExists.register_backend`.
