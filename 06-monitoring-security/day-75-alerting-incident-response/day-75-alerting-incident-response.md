# Day 75: Prometheus Alertmanager, Severity Tiers & Incident Command

## 1. Theoretical Foundation

### The Role of Prometheus Alertmanager
Prometheus itself does **not** send emails, SMS, or Slack messages.
Prometheus evaluates alert rules and fires active alerts to **Alertmanager**:
- **Deduplication**: Merges identical alerts from redundant Prometheus servers.
- **Grouping**: Bundles 20 related container crash alerts from the same cluster into a **single summary message** to prevent alert flooding.
- **Inhibition**: Suppresses low-priority downstream alerts if an upstream root-cause alert is already firing (e.g. if `NetworkSwitchDown` is firing, suppress all `NodeDown` alerts!).
- **Silencing**: Mutes notifications during scheduled maintenance windows.

```
[ Prometheus Server 1 ] \
                         +---> [ Alertmanager ] ---> [ Deduplicate & Group ] ---> [ PagerDuty / Slack ]
[ Prometheus Server 2 ] /             |
                               [ Inhibit & Silence ]
```

---

## 2. Severity Classification Matrix

Enterprise incident response categorizes incidents into strict priority tiers:

| Severity | Impact | Response Time (SLA) | Notification Channel | Example |
| :--- | :--- | :--- | :--- | :--- |
| **P1 / Critical** | Complete revenue loss; core customer journey broken for all users | **< 15 minutes** (24/7/365) | PagerDuty / Phone Call / SMS | Payment gateway failing, database down, data loss |
| **P2 / High** | Significant degradation; core feature partially broken with no workaround | **< 30 minutes** | PagerDuty / On-Call Slack | Search API broken, elevated 5xx error rate (5%) |
| **P3 / Medium** | Minor feature bug with workaround; internal system impacted | **< 4 hours** (Business Hours) | Team Slack channel | Admin reporting slow, non-critical background batch delayed |
| **P4 / Low** | Cosmetic bug or minor informational question | Next Sprint / Backlog | Jira Ticket | Typo on web UI, minor latency blip |

---

## 3. Prometheus Alerting Rules Definition (`alerts.yaml`)

```yaml
groups:
  - name: production-api-alerts
    rules:
      - alert: HighHttp5xxRate
        expr: |
          sum(rate(http_requests_total{status=~"5.."}[5m]))
            /
          sum(rate(http_requests_total[5m])) * 100 > 5
        for: 2m # Condition must persist for 2 continuous minutes before firing
        labels:
          severity: critical
          team: checkout-sre
        annotations:
          summary: "High HTTP 5xx error rate on {{ $labels.job }}"
          description: "HTTP 5xx error rate is currently at {{ $value | printf \"%.2f\" }}% on service {{ $labels.job }}."
          runbook_url: "https://wiki.company.internal/runbooks/high-5xx-errors"
```

---

## 4. The Incident Command System (ICS) for DevOps Outages

When a P1/Critical incident fires, the on-call engineer assumes the role of **Incident Commander (IC)**:
1. **Declare the Incident**: Post in `#incident-war-room` and start an audio bridge.
2. **Assign Roles**:
   - **Incident Commander (IC)**: Directs the investigation, authorizes actions, maintains focus. Does NOT write code!
   - **Operations Lead**: The hands-on engineer inspecting logs, diagnosing metrics, and running commands.
   - **Communications Lead**: Updates customer-facing status pages (`status.company.com`) and executive stakeholders every 20 minutes.
3. **Mitigate First, Investigate Later**: Prioritize restoring user service (e.g. roll back code, scale up instances, enable maintenance cache) before spending hours diagnosing root cause!

---

## 5. Interview & Review Questions
1. **What is the `for` duration in a Prometheus alert rule and why is it important?**
   - *Answer*: The `for` clause specifies how long the evaluation expression must continuously remain true before the alert changes state from `Pending` to `Firing`. This prevents brief transient spikes (e.g. a 5-second CPU burst during container boot) from triggering false-positive pager alerts.
2. **What is Alert Inhibition in Alertmanager?**
   - *Answer*: Inhibition is a feature that mutes a set of alerts if another specific alert is already active. For example, if an alert indicates an entire data center or network switch is unreachable, Alertmanager inhibits hundreds of individual node reachability and application timeout alerts for that data center, keeping notifications focused on the root problem.
