# Phase 6: Monitoring, Security & Reliability (Days 71–80)

Deploying infrastructure is only the beginning. Keeping production systems fast, secure, resilient, and available 24/7/365 requires **Observability (Prometheus, Grafana)**, **DevSecOps**, **Incident Management**, and **Disaster Recovery**.

---

## 📅 Daily Learning Index

| Day | Topic | In-Depth Learning Guide | Key Concepts |
| :--- | :--- | :--- | :--- |
| **71** | **Observability Fundamentals & SRE Metrics** | [Day 71 Guide](./day-71-monitoring-metrics-observability.md) | Metrics vs Logs vs Traces, Golden Signals, SLIs, SLOs, SLAs, Alert Fatigue |
| **72** | **Prometheus Architecture & PromQL Mastery** | [Day 72 Guide](./day-72-prometheus-fundamentals.md) | Pull vs Push model, Exporters (Node Exporter), Time-series labels, PromQL vector functions |
| **73** | **Grafana Dashboard Engineering** | [Day 73 Guide](./day-73-grafana-dashboards.md) | Data Sources, Dashboard variables, Panel visualizations, Alert rules, Dashboard-as-Code |
| **74** | **AWS CloudWatch Deep Dive & Alarms** | [Day 74 Guide](./day-74-aws-cloudwatch-logs-alarms.md) | Log Groups/Streams, Metric Filters, CloudWatch Alarms, SNS integrations, Logs Insights queries |
| **75** | **Alerting Engineering & Incident Response** | [Day 75 Guide](./day-75-alerting-incident-response.md) | Alertmanager routing, Severity tiers (P1-P4), On-Call escalation, Incident Command, Runbooks |
| **76** | **DevSecOps & Vulnerability Management** | [Day 76 Guide](./day-76-devsecops-vulnerability-management.md) | Shift-Left security, SAST, DAST, SCA (Software Composition Analysis), Trivy, Snyk, SonarQube |
| **77** | **Cloud Security Auditing & IAM Hardening** | [Day 77 Guide](./day-77-iam-secrets-cloud-security-review.md) | IAM permission boundaries, KMS envelope encryption, AWS CloudTrail audit logs, AWS GuardDuty |
| **78** | **Backups, Disaster Recovery & RTO/RPO** | [Day 78 Guide](./day-78-backups-disaster-recovery-rto-rpo.md) | RTO vs RPO, DR Strategies (Backup/Restore, Pilot Light, Warm Standby, Multi-Region Active/Active) |
| **79** | **Linux Performance & Capacity Troubleshooting**| [Day 79 Guide](./day-79-performance-capacity-troubleshooting.md)| Brendan Gregg's USE & RED methods, `vmstat`, `iostat`, `perf`, CPU saturation, kernel bottlenecks |
| **80** | **Chaos Engineering & Blameless Postmortems** | [Day 80 Guide](./day-80-reliability-review-game-day.md) | Chaos Engineering (Chaos Mesh), GameDays, Blameless Postmortems, Root Cause Analysis (5 Whys) |

---

## 🎯 Phase 6 Goals & Milestones
By the end of Phase 6, you should be able to:
1. Define and measure Service Level Indicators (SLIs) and Service Level Objectives (SLOs).
2. Write production PromQL queries and build interactive Grafana dashboards.
3. Configure Alertmanager with deduplication, grouping, and escalation runbooks.
4. Integrate DevSecOps vulnerability scanners (SAST, SCA, Container Scans) into CI/CD pipelines.
5. Formulate enterprise Disaster Recovery strategies with strict RTO/RPO targets.
