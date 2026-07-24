# ADR 0001: Pure Ruby Probabilistic Data Structure Implementation

## Context
High-scale Rails applications require ultra-fast existence checks without native C extension dependencies that break JRuby or cause gem compilation failures in restricted container environments.

## Decision
Implement optimal Bloom Filter, Scalable Bloom Filter, Cuckoo Filter, and HyperLogLog algorithms natively in pure Ruby using double hashing (MurmurHash3 / FNV-1a / SHA256) and bitwise operations on byte buffers.

## Consequences
- 100% cross-platform compatibility across MRI Ruby 3.0+, JRuby, and all operating systems.
- Zero native C-extension compilation issues.
- Thread-safe mutation locking using Mutex synchronization.
