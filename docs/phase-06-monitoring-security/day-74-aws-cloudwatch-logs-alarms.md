# Day 74: AWS CloudWatch Logs, Metric Filters & Composite Alarms

## 1. Theoretical Foundation

In hybrid and AWS-native architectures, **Amazon CloudWatch** acts as the managed centralized control plane for all AWS services (Lambda, ECS, EKS, RDS, API Gateway).

### Key Architectural Units
- **Log Group**: A collection of log streams that share the same retention, monitoring, and access control settings (e.g. `/aws/eks/prod-cluster/cluster`).
- **Log Stream**: A sequence of log events originating from the same source (e.g. a specific EC2 instance or container ID).
- **Metric Filter**: A real-time pattern matching engine that scans incoming plain text or JSON logs and converts matching lines into numerical CloudWatch metrics.

---

## 2. Advanced Metric Filters (JSON Logs)

Modern container applications emit structured JSON logs. CloudWatch Metric Filters can parse JSON tokens natively without regular expressions:

```json
{
  "timestamp": "2026-10-15T12:00:00Z",
  "level": "ERROR",
  "http_status": 500,
  "response_time_ms": 1420,
  "service": "checkout-api"
}
```

### JSON Metric Filter Pattern:
`{ $.http_status >= 500 }`
- **Metric Namespace**: `CustomApp/Checkout`
- **Metric Name**: `Http5xxErrorCount`
- **Metric Value**: `1`

---

## 3. CloudWatch Composite Alarms

Standard CloudWatch alarms trigger when a single metric breaches a threshold. However, this often causes alert storms (e.g., if a network switch dies, 50 different CPU, database, and latency alarms fire simultaneously).
**Composite Alarms** use boolean logic (`AND`, `OR`) across multiple alarms to eliminate false alarms and reduce paging noise:

```text
ALARM Rule:
(ALARM("HighAppLatency") AND ALARM("High5xxErrors")) AND NOT ALARM("MaintenanceWindowActive")
```
The pager only triggers when both user latency **AND** server error rates are failing, and suppresses alerts during scheduled maintenance!

---

## 4. Log Retention & Cost Hygiene

By default, CloudWatch Log Groups retain logs **"Never Expire" (Forever)**. Over months, forgotten development and debug log groups consume thousands of dollars in storage!

```bash
# Update Log Group retention to 30 days
aws logs put-retention-policy \
  --log-group-name "/aws/ecs/production-api" \
  --retention-in-days 30
```

---

## 5. Interview & Review Questions
1. **What is the difference between standard CloudWatch Alarms and Composite Alarms?**
   - *Answer*: Standard alarms monitor a single metric against a threshold. Composite alarms evaluate boolean conditions (`AND`, `OR`, `NOT`) across multiple underlying alarms, preventing false alarms and alerting only when multiple correlated failure conditions occur simultaneously.
2. **What is the financial danger of the default CloudWatch Logs retention setting?**
   - *Answer*: The default setting is "Never Expire". Without automated retention policies, high-throughput applications accumulate terabytes of historical logs indefinitely, leading to perpetually increasing AWS billing charges for unneeded stale logs.
