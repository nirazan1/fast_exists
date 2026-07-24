# ADR 0003: ActiveRecord Lifecycle Synchronization

## Context
When records are created or updated, probabilistic filters must stay synchronized with database mutations to prevent false negatives.

## Decision
Use `after_commit :fast_exists_sync_on_commit` lifecycle hooks to ensure filter writes occur only after database transactions successfully commit.

## Consequences
- Prevents dirty filter contamination if a database transaction is rolled back.
- Supports bulk sync via `User.rebuild_fast_exists!` rake tasks or background Sidekiq jobs.
