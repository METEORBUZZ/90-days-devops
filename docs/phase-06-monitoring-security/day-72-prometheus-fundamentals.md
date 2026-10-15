# Day 72: Prometheus Fundamentals, Architecture & PromQL

## 1. Theoretical Foundation

### What is Prometheus?
Prometheus is the CNCF graduated open-source monitoring and alerting toolkit designed specifically for dynamic, cloud-native environments (Kubernetes, microservices).

### The Prometheus Pull Model vs. Push Model
- **Push Model (e.g. CloudWatch Agent, Datadog)**: Every client agent pushes metrics over the network to a central backend. If thousands of nodes reboot simultaneously, they can flood and crash the ingestion server.
- **Pull Model (Prometheus)**: Prometheus **scrapes (pulls)** metrics over HTTP from endpoints (`/metrics`) on a regular schedule (e.g. every 15s). Prometheus controls ingestion rates, automatically detects when targets die, and prevents network flooding!

```
+-------------------------------------------------------------------------+
|                                PROMETHEUS                               |
|                                                                         |
|  [ Retrieval / Scrape Engine ] --------> HTTP GET /metrics              |
|               |                                                         |
|               v                                                         |
|  [ TSDB (Time Series Database) ]                                        |
|  - In-memory chunk cache + Local SSD blocks                             |
|               |                                                         |
|               v                                                         |
|  [ PromQL Engine ]                                                      |
+-------------------------------------------------------------------------+
       |                                             |
       v (Scrapes targets)                           v (Pushes alerts)
[ Targets: Node Exporter, App /metrics ]      [ Alertmanager ]
```

---

## 2. Prometheus Metric Types

Prometheus defines 4 core metric types:
1. **Counter**: A cumulative metric that only ever **increases** (or resets to 0 on restart).
   - *Example*: `http_requests_total`, `packet_drop_count`.
2. **Gauge**: A metric that can go **up or down** arbitrarily.
   - *Example*: `node_memory_MemAvailable_bytes`, `temperature_celsius`, `concurrent_active_users`.
3. **Histogram**: Samples observations (usually request durations or response sizes) and counts them in configurable bucket intervals.
   - *Example*: `http_request_duration_seconds_bucket{le="0.2"}`.
4. **Summary**: Similar to histogram, but calculates configurable quantiles (e.g. $\phi = 0.95, 0.99$) directly on the client side.

---

## 3. PromQL (Prometheus Query Language) Cheat Sheet

PromQL operates on time-series vectors:
- **Instant Vector**: A set of time series containing a single sample for each time series, all at the current timestamp.
- **Range Vector**: A set of time series containing a buffer of data points over a historical duration (e.g. `[5m]`).

### Production PromQL Queries

#### 1. Calculate Request Rate (Per Second over 5 Minutes)
```promql
# rate() handles counter resets automatically!
rate(http_requests_total[5m])

# Filter by status code and service label
rate(http_requests_total{status=~"5..", job="order-api"}[5m])
```

#### 2. Percentage of 5xx HTTP Errors (Error Ratio)
```promql
sum(rate(http_requests_total{status=~"5.."}[5m]))
  /
sum(rate(http_requests_total[5m])) * 100
```

#### 3. CPU Utilization Percentage per Node
```promql
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

#### 4. Memory Utilization Percentage per Node
```promql
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
```

#### 5. 99th Percentile (p99) Request Latency via Histogram
```promql
# Calculates the latency experienced by 99% of users over the last 5 minutes
histogram_quantile(0.99, sum by (le) (rate(http_request_duration_seconds_bucket[5m])))
```

---

## 4. Configuring Prometheus Scrape Targets (`prometheus.yml`)

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: "node_exporter"
    static_configs:
      - targets: ["10.0.1.20:9100", "10.0.1.21:9100"]

  - job_name: "kubernetes-pods"
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
```

---

## 5. Interview & Review Questions
1. **Why must you use `irate` or `rate` on Counters instead of reading raw Counter values?**
   - *Answer*: Counters are monotonically increasing values that accumulate continuously and reset to 0 upon application restart. A raw counter value tells you nothing about current workload. `rate()` calculates the per-second rate of increase over a sliding window while automatically detecting and compensating for process restart resets.
2. **What is the difference between `rate()` and `irate()` in PromQL?**
   - *Answer*: `rate()` calculates the average per-second rate of change over the entire specified time window (e.g. `[5m]`), smoothing out volatile spikes. `irate()` (instant rate) calculates the rate of change based exclusively on the last two data points in the range window, making it highly responsive to immediate, transient traffic bursts.
