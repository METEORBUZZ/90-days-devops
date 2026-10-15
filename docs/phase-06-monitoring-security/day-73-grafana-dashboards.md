# Day 73: Grafana Dashboard Design, Panels & Observability Engineering

## 1. Theoretical Foundation

### What is Grafana?
Grafana is the premier multi-platform analytics and interactive data visualization platform. It connects to multiple heterogeneous data sources simultaneously (Prometheus, AWS CloudWatch, Elasticsearch, PostgreSQL, Loki, Jaeger) to provide unified single-pane-of-glass dashboards.

---

## 2. Core Grafana Concepts

1. **Data Source**: The storage backend holding time-series metrics, logs, or traces (e.g. `http://prometheus-server:9090`).
2. **Panels**: The individual visual building blocks of a dashboard:
   - **Time Series**: Standard line/bar chart for continuous metrics over time.
   - **Stat / Gauge**: Single large numeric display for current status (e.g. "99.98% SLO", "4 Active Nodes").
   - **Heatmap**: Visualizes request latency distributions over time.
   - **Logs**: Displays streaming logs from Loki or Elasticsearch.
3. **Variables (Template Dropdowns)**: Allows users to dynamically change panel filters (e.g. choose `$environment = "prod"`, `$namespace = "checkout"`, or `$node = "worker-01"`) without modifying queries.

---

## 3. Best Practices in Dashboard Layout (The UX of SRE)

A dashboard should tell a clear operational story from top to bottom:

```
+-----------------------------------------------------------------------------------------+
|  ROW 1: HIGH-LEVEL HEALTH & EXECUTIVE STATUS (Gauges / Stats)                          |
|  [ Cluster Status: HEALTHY ]   [ Global Request Rate: 4.2k/s ]   [ Error Rate: 0.02% ]  |
+-----------------------------------------------------------------------------------------+
|  ROW 2: GOLDEN SIGNALS (Time Series Charts)                                             |
|  [ Panel: Traffic (RPS) ]      [ Panel: Latency (p50, p95, p99) ]   [ Panel: 5xx Errors]|
+-----------------------------------------------------------------------------------------+
|  ROW 3: COMPUTE INFRASTRUCTURE (Drill-Down)                                             |
|  [ Node CPU Utilization % ]    [ Node Memory Available ]         [ Disk I/O Wait ]     |
+-----------------------------------------------------------------------------------------+
```

---

## 4. Dashboard as Code (Provisioning JSON)

Never manually configure production Grafana dashboards by clicking in the UI! If the Grafana container restarts or the server is migrated, manual changes are lost.
Define Dashboards as Code in Git and provision them automatically via Kubernetes ConfigMaps or Grafana provisioning folders:

```yaml
# /etc/grafana/provisioning/dashboards/dashboards.yaml
apiVersion: 1
providers:
  - name: 'production-dashboards'
    orgId: 1
    folder: 'SRE Fleet'
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    options:
      path: /var/lib/grafana/dashboards
```

---

## 5. Interview & Review Questions
1. **What is Dashboard as Code and why is it essential in modern DevOps?**
   - *Answer*: Dashboard as Code treats Grafana dashboard JSON models as version-controlled software artifacts stored in Git. This enables code reviews, version rollback, automated CI validation, and automatic deployment via Helm or ConfigMaps, eliminating drift caused by manual UI edits.
2. **What are Grafana Variables and how do they improve dashboard reusability?**
   - *Answer*: Variables parameterize PromQL or SQL queries (e.g. `rate(http_requests_total{instance=~"$node"}[5m])`). Instead of creating 50 separate dashboards for 50 cluster nodes, a single dashboard with a `$node` dropdown variable dynamically queries and displays metrics for whichever node is selected.
