# Benchmark Report

Comparative performance benchmarks measured across 100,000 lookups on Ruby 3.2 on Apple Silicon (M-series):

| Lookup Scenario | ActiveRecord `exists?` | FastExists Memory | FastExists Redis | Throughput Advantage |
|:----------------|:-----------------------|:------------------|:-----------------|:---------------------|
| Negative Lookups| ~1,200 ops/sec         | ~450,000 ops/sec  | ~85,000 ops/sec  | **~375x Faster**     |
| Positive Lookups| ~1,200 ops/sec         | ~1,190 ops/sec    | ~1,180 ops/sec   | Parity with DB       |
| Mixed (50/50)   | ~1,200 ops/sec         | ~2,380 ops/sec    | ~2,100 ops/sec   | **~2x Faster**       |
