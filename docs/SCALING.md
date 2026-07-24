# Scaling & Multi-Tenant Guide

## Multi-Tenant Isolation

For multi-tenant Rails applications (e.g. Apartment, ActsAsTenant), specify tenant resolution via lambdas:

```ruby
class User < ApplicationRecord
  fast_exists :email, namespace: ->(record_or_context) { Current.account&.id || "global" }
end
```

Each tenant will automatically maintain an independent, isolated probabilistic filter bit-vector.
