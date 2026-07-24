# Frequently Asked Questions (FAQ)

### Q: Can FastExists ever produce a False Negative (say a record doesn't exist when it actually does)?
**A: Absolutely NOT.** Bloom filters and Cuckoo filters mathematically guarantee **zero false negatives**. If FastExists returns `false`, the item is guaranteed to not be in the filter or database.

### Q: What happens when a False Positive occurs?
**A: FastExists falls back safely to the database.** If the filter returns `true` (Maybe Present), FastExists queries the database. If the DB confirms the record is missing, FastExists increments its false positive metric and returns `false`. The database is always the ultimate source of truth.

### Q: Can I delete items from a standard Bloom filter?
**A: No**, standard Bloom filters do not support item deletion. If you need deletion support, use `FastExists::Bloom::Counting` or `FastExists::Probabilistic::Cuckoo`.
