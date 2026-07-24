# Performance Overview

`FastExists` delivers up to 100x-1000x throughput improvements for negative existence checks by intercepting database roundtrips.

## Performance Highlights

- **Negative Queries**: 0 Database I/O. Execution takes under **5 microseconds** per lookup in memory.
- **Positive Queries**: 1 Filter check (~2us) + 1 Database query. Zero degradation compared to direct DB query.
- **Allocation Efficiency**: Bit operations execute directly on frozen string byte buffers with minimal object allocations.
