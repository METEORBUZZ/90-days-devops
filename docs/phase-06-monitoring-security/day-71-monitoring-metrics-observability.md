# Day 71: Observability Fundamentals, The 3 Pillars & SRE Metrics

## 1. Theoretical Foundation

### Monitoring vs. Observability
- **Monitoring (Passive)**: Tells you **WHEN** something is broken (e.g. "Server CPU is > 90%", "HTTP 500 error rate spiked").
- **Observability (Active)**: Measures the internal states of a system based on its external outputs. It allows you to ask **WHY** something is broken, even for novel, complex failure modes you never anticipated!

### The Three Pillars of Observability (M-L-T)
```
+-------------------------------------------------------------------------------+
|                                OBSERVABILITY                                  |
+-------------------------------------------------------------------------------+
           |                               |                               |
           v                               v                               v
     [ METRICS ]                       [ LOGS ]                       [ TRACES ]
(Time-series numbers)            (Event text stream)             (Request journeys)
- CPU %, Memory MB, Latency ms   - Timestamped records           - Distributed spans across
- Cheap to store & query         - Rich contextual payload       - microservices via OpenTelemetry
- Aggregations & Alarms          - High storage volume           - Identifies bottleneck services
```

---

## 2. The 4 Golden Signals of SRE (Google SRE Book)

When monitoring distributed user-facing systems, prioritize the **Four Golden Signals**:
1. **Latency**: The time it takes to service a request (differentiating successful request latency from error request latency).
2. **Traffic**: Demand placed on your system (e.g., HTTP requests per second, network I/O).
3. **Errors**: The rate of requests that fail (e.g., HTTP 500 status codes, database timeouts).
4. **Saturation**: How "full" your service is. Measures resource constraints (memory usage, thread pool limits, connection pool queues).

---

## 3. SLA vs. SLO vs. SLI

| Term | Full Name | Definition | Example |
| :--- | :--- | :--- | :--- |
| **SLI** | **Service Level Indicator** | A quantifiable metric measuring real-time performance. | Percentage of successful HTTP requests returned in < 200ms over 30 days. |
| **SLO** | **Service Level Objective** | Internal target agreed upon by Engineering and Product. | **99.9%** of requests must meet the SLI over a rolling 30-day window. |
| **SLA** | **Service Level Agreement** | Legal contract with customers with financial penalties if breached. | **99.5%** uptime; if breached, customer receives 10% billing credit. |

### Error Budgets
An **Error Budget** is the allowable failure headroom:
$$\text{Error Budget} = 100\% - \text{SLO}$$
- For a **99.9% SLO**, your error budget is **0.1%** (approx. 43 minutes of downtime per month).
- **SRE Culture**: If the error budget is healthy, developers can deploy fast and release new features. If the error budget is exhausted, feature deployments are frozen, and all engineering effort is redirected to reliability and technical debt!

---

## 4. Combating Alert Fatigue

**Alert Fatigue** happens when engineers receive dozens of non-actionable, noisy pager alerts every night. Over time, engineers ignore notifications, leading to real catastrophic outages being missed.

### Rules for Production Pagers:
1. **Every Alert Must Be Actionable**: If an alert fires and the engineer does not need to take immediate corrective action, **delete the alert**!
2. **Alert on Symptoms, Not Causes**: Do not page on "CPU at 85%". Page when **"User-facing checkout latency > 1.5s"** or **"HTTP 5xx error rate > 1%"**!
3. **Every Alert Must Have a Runbook Link**: The alert notification must include a clickable link to a step-by-step diagnostic and remediation runbook.

---

## 5. Interview & Review Questions
1. **Explain the difference between an SLI, an SLO, and an SLA.**
   - *Answer*: An SLI is the actual metric measured (e.g. successful request percentage). An SLO is the internal reliability target set by the engineering team (e.g. 99.9% of requests succeed). An SLA is the external commercial contract with customers specifying financial refunds or penalties if the service fails to meet the SLA threshold.
2. **Why is high CPU utilization alone often a poor choice for a high-priority PagerDuty alarm?**
   - *Answer*: High CPU utilization does not necessarily mean users are experiencing degraded service; modern multi-threaded applications and batch jobs are designed to run near capacity. Alerting on CPU creates noise and alert fatigue. Pagers should trigger on customer-impacting symptoms (high latency, elevated 5xx error rates, or dropped transactions).
