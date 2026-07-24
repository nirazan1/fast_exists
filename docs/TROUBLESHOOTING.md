# Troubleshooting Guide

### Issue: High False Positive Rate
- **Symptom**: `FastExists.stats[:false_positive_rate]` is > 1%.
- **Solution**: Increase `expected_elements` in your initializer or run `FastExists::Optimizer::AiAdvisor.analyze(User)` to get recommended parameters.

### Issue: Redis Connection Error
- **Symptom**: `FastExists::BackendError: Redis client not configured`.
- **Solution**: Set `config.redis = Redis.new(...)` in `config/initializers/fast_exists.rb`.
