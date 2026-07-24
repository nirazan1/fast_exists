# FastExists Architecture Guide

`FastExists` is designed around Clean Architecture and SOLID design principles.

## Core Architectural Layers

1. **Domain Layer (`lib/fast_exists/bloom/`, `lib/fast_exists/probabilistic/`)**:
   Pure, decoupled data structures implementing Bloom Filters, Scalable Bloom Filters, Counting Bloom Filters, Cuckoo Filters, and HyperLogLog.
2. **Backend Abstraction Layer (`lib/fast_exists/backends/`)**:
   Standardized interface (`add`, `contains?`, `clear`, `stats`) isolating bit-vector persistence from application logic.
3. **ActiveRecord Integration Layer (`lib/fast_exists/active_record/`)**:
   Zero-monkey-patch macro DSL extending ActiveRecord models with lifecycle callbacks and dynamic methods.
4. **Telemetry & Instrumentation Layer (`lib/fast_exists/statistics/`, `lib/fast_exists/instrumentation/`)**:
   ActiveSupport::Notifications, Prometheus metrics, and OpenTelemetry integrations tracking avoided queries and hit ratios.

```
+-------------------------------------------------------+
|                ActiveRecord Model DSL                 |
|     User.email_exists? / User.username_available?     |
+---------------------------+---------------------------+
                            |
                            v
+-------------------------------------------------------+
|                    FastExists Backend                  |
|          (Memory / Redis / RedisBloom / File)         |
+---------------------------+---------------------------+
                            |
             +--------------+--------------+
             |                             |
             v                             v
   [Definitely Not Present]         [Maybe Present]
             |                             |
             v                             v
   Return false immediately         Query Database
       (0 DB Queries)               (Final Source of Truth)
```
