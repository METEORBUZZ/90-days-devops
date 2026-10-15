# Day 85: Capstone Observability — Dashboards, Alertmanager & Runbooks

## 1. Observability Architecture

The observability stack monitors the CloudOrders application across all layers:
1. **Application Layer**: Custom Prometheus metrics (`http_requests_total`, `http_request_duration_seconds`) emitted by the FastAPI container.
2. **Kubernetes Layer**: `kube-state-metrics` tracking pod restarts, scheduling states, and HPA utilization.
3. **Infrastructure Layer**: `node_exporter` capturing CPU, RAM, disk I/O, and network socket metrics.
4. **Grafana Dashboards**: Unified visual dashboards displaying the 4 Golden Signals.
5. **Alertmanager**: Dispatches critical notifications to Slack and PagerDuty with links to actionable runbooks.

---

## 2. Production Prometheus Alert Rules (`alerts.yaml`)

```yaml
groups:
  - name: cloudorders-production-alerts
    rules:
      - alert: HighOrderErrorRate
        expr: |
          sum(rate(http_requests_total{status=~"5.."}[5m]))
            /
          sum(rate(http_requests_total[5m])) * 100 > 2.0
        for: 2m
        labels:
          severity: critical
          tier: backend
        annotations:
          summary: "CloudOrders 5xx error rate exceeded 2%!"
          description: "Current error rate is {{ $value | printf \"%.2f\" }}% over the last 5 minutes."
          runbook_url: "https://wiki.company.internal/runbooks/high-error-rate"

      - alert: HighP99Latency
        expr: |
          histogram_quantile(0.99, sum by (le) (rate(http_request_duration_seconds_bucket[5m]))) > 0.500
        for: 3m
        labels:
          severity: warning
        annotations:
          summary: "CloudOrders p99 latency exceeded 500ms!"
          description: "99% of requests are taking > {{ $value }}s to respond."
          runbook_url: "https://wiki.company.internal/runbooks/high-latency"
```

---

## 3. Production Incident Runbook (`RUNBOOK_HIGH_5XX.md`)

```markdown
# Runbook: High HTTP 5xx Error Rate Triage

## Severity: P1 / Critical
**Target Service**: `cloudorders-api`  
**Alert Definition**: HTTP 5xx error rate > 2% for 2 minutes.

### 1. Initial Assessment (First 2 Minutes)
1. Verify customer impact on the public status page and Grafana dashboard.
2. Check if a deployment occurred recently:
   ```bash
   kubectl rollout history deployment/cloudorders -n production
   ```
3. If an erroneous deployment completed < 15 minutes ago, **EXECUTE IMMEDIATE ROLLBACK FIRST**:
   ```bash
   kubectl rollout undo deployment/cloudorders -n production
   ```

### 2. Live Diagnostics
If rollback does not resolve the issue or no recent deployment occurred:
1. Check pod status:
   ```bash
   kubectl get pods -n production -l app.kubernetes.io/name=cloudorders
   ```
2. Inspect recent application error logs:
   ```bash
   kubectl logs -l app.kubernetes.io/name=cloudorders -n production --tail=100 | grep -i -E "(error|exception|fatal)"
   ```
3. Check PostgreSQL database connectivity:
   ```bash
   aws rds describe-db-instances --db-instance-identifier cloudorders-prod-db \
     --query "DBInstances[].[DBInstanceStatus, Endpoint.Address]" --output table
   ```

### 3. Escalation & Communication
- If database CPU is at 100%, contact the Database On-Call Team: `@dba-oncall`.
- Post updates to the incident channel `#incident-war-room` every 20 minutes until resolved.
```

---

## 4. Key Takeaways & Review
- Every alert has an explicit `runbook_url` guiding the on-call engineer during high-stress outages.
- The runbook prioritizes **immediate service mitigation (rollback)** before root-cause investigation.
