# 🏢 Enterprise Adaptive Multi-Tenant Bloom Filter Management

SaaS applications often serve thousands of tenants with dramatically different data sizes (e.g. 10 Enterprise customers vs 4,500 SMB customers).

- Allocating a dedicated Bloom filter per tenant wastes memory (4,500 Redis keys).
- Using a single global Bloom filter increases false positives and reduces operational flexibility.

`FastExists` provides **Adaptive Multi-Tenant Bloom Filter Management** (`:adaptive`), automatically classifying tenants into optimal pools based on record volume and lookup traffic.

---

## ⚙️ Configuration

```ruby
# config/initializers/fast_exists.rb
FastExists.configure do |config|
  config.backend = :redis
  config.multi_tenant = true
  config.tenant_strategy = :adaptive # :global, :per_tenant, :shared, :adaptive

  # Configurable record count classification thresholds
  config.tenant_thresholds = {
    tiny: 10_000,
    small: 100_000,
    medium: 1_000_000
  }
end
```

---

## 🎯 Supported Strategies

1. **`:global` (`GlobalStrategy`)**: Shared Bloom filter (`fast_exists:global`). Hashing `tenant_id:attribute:value`.
2. **`:per_tenant` (`PerTenantStrategy`)**: Dedicated Bloom filter per tenant (`fast_exists:tenant:<id>`). Best for large Enterprise tenants (>1,000,000 records).
3. **`:shared` (`SharedStrategy`)**: Configurable shared pools (`small`, `medium`, `large`).
4. **`:adaptive` (`AdaptiveStrategy`)**: Recommended default. Automatically classifies tenants:
   - `Tiny` (< 10,000 records) -> Shared `tiny` pool (`fast_exists:pool:tiny`)
   - `Small` (10,000–100,000 records) -> Shared `small` pool (`fast_exists:pool:small`)
   - `Medium` (100,000–1,000,000 records) -> Shared `medium` pool (`fast_exists:pool:medium`)
   - `Large` (> 1,000,000 records) -> Dedicated filter (`fast_exists:tenant:<id>`)

---

## 🔑 Redis Key Layout

```text
fast_exists:global
fast_exists:pool:tiny
fast_exists:pool:small
fast_exists:pool:medium
fast_exists:tenant:42
fast_exists:tenant:83
```

---

## 📈 Promotion & Demotion Recommendations

As tenants grow or shrink, `FastExists.doctor!` and `FastExists.analyze!` recommend promotion or demotion actions.

> [!IMPORTANT]
> **Zero Automatic Data Migration**: Recommendations are strictly read-only. Automatic rebalancing or migration never occurs without explicit developer action.

---

## 📊 Analytics & Doctor Output Example

For an application with 4,287 tenants (3,901 Tiny, 312 Small, 64 Medium, 10 Large):

- **Per-Tenant Strategy**: 4,287 Redis keys (~220 MB RAM)
- **Adaptive Strategy**: 13 Redis keys (~48 MB RAM)
- **Memory Reduction**: **78%**
- **Redis Key Reduction**: **99.7%**
