# Memory Sizing & Sizing Formulas

## Formula for Bloom Filter Memory Requirement

Given:
- $n$ = Expected number of items
- $p$ = False positive target probability (e.g. 0.001 = 0.1%)

Bit Size ($m$):
$$m = \left\lceil - \frac{n \ln(p)}{(\ln 2)^2} \right\rceil$$

Hash Functions ($k$):
$$k = \left\lceil \frac{m}{n} \ln 2 \right\rceil$$

## Reference Memory Chart

| Expected Items ($n$) | Target FP Rate ($p$) | Bit Size ($m$) | Memory Required | Hash Count ($k$) |
|:---------------------|:---------------------|:---------------|:----------------|:-----------------|
| 100,000              | 0.1% (0.001)         | 1,437,759 bits | ~175 KB         | 10               |
| 1,000,000            | 0.1% (0.001)         | 14,377,588 bits| ~1.71 MB        | 10               |
| 10,000,000           | 0.1% (0.001)         | 143,775,876 bits| ~17.1 MB       | 10               |
| 100,000,000          | 0.1% (0.001)         | 1,437,758,757 bits| ~171.4 MB    | 10               |
