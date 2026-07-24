# 🧠 FastExists Performance Intelligence Suite

The **FastExists Performance Intelligence Suite** extends `fast_exists` into a first-class operational diagnostic, application analyzer, architectural auditor, recommendation generator, and multi-format reporting engine for Ruby on Rails applications.

---

## 🏛️ Public API

### 1. `FastExists.stats(format: :console)`
Displays runtime statistics formatted for various outputs.

```ruby
# Hash output
FastExists.stats

# Formatted outputs
FastExists.stats(format: :json)
FastExists.stats(format: :yaml)
FastExists.stats(format: :markdown)
```

### 2. `FastExists.health!`
Operational health check inspecting backend availability, Redis connectivity, RedisBloom availability, memory usage, capacity, occupancy, false positive rate trends, synchronization health, and version compatibility.

```ruby
FastExists.health!
# => {
#   overall_status: :healthy,
#   checks: [
#     { name: "Backend Availability", status: :pass, message: "Backend 'memory' is registered and active" },
#     { name: "False Positive Rate", status: :pass, message: "False positive rate healthy" }
#   ]
# }
```

### 3. `FastExists.analyze!`
Strictly read-only analysis of ActiveRecord models, column candidates, row counts, indexes, and expected query savings.

```ruby
FastExists.analyze!
FastExists.analyze!(User)
FastExists.analyze!(User, :email)
FastExists.analyze!(models: [User, Customer], output: :json)
```

### 4. `FastExists.audit!`
Deep architectural audit detecting missing unique indexes on uniquely validated attributes, non-indexed existence queries, duplicate lookup patterns, and capacity risks.

```ruby
FastExists.audit!
# => { audit_score: 95, grade: "A", findings: [...] }
```

### 5. `FastExists.doctor!`
Actionable diagnostic recommendation engine inspired by `flutter doctor` and `brew doctor`. Generates copy-pasteable model DSL macros, database index migrations, initializers, and backend recommendations.

```ruby
FastExists.doctor!
FastExists.doctor!(format: :html)
FastExists.doctor!(format: :markdown)
```

### 6. `FastExists.report!`
Generates comprehensive executive reports summarizing statistics, health, model analysis, audit findings, doctor recommendations, and growth forecasts.

```ruby
FastExists.report!(format: :html, output: "fast_exists_report.html")
FastExists.report!(format: :markdown)
FastExists.report!(format: :pdf, output: "report.pdf")
FastExists.report!(compare: "reports/previous.json")
```

---

## 💻 CLI Commands

```bash
fast_exists stats [--json | --yaml | --markdown]
fast_exists health
fast_exists analyze [--json | --yaml]
fast_exists audit
fast_exists doctor [--html | --markdown | --json]
fast_exists report [--html | --markdown | --json | --pdf | --csv] [-o report.html]
```

---

## ⚙️ Rake Tasks

```bash
rails fast_exists:stats
rails fast_exists:health
rails fast_exists:analyze
rails fast_exists:audit
rails fast_exists:doctor
rails fast_exists:report FORMAT=html OUTPUT=report.html
```

---

## 🚀 CI/CD Integration (GitHub Actions)

Add FastExists performance reporting to your GitHub Actions workflow:

```yaml
- name: Run FastExists Performance Audit
  run: bundle exec rake fast_exists:report FORMAT=html OUTPUT=fast_exists_report.html

- name: Upload FastExists Report Artifact
  uses: actions/upload-artifact@v3
  with:
    name: fast-exists-report
    path: fast_exists_report.html
```
