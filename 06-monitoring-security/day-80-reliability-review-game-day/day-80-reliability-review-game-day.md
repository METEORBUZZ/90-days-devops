# Day 80: Chaos Engineering, GameDays & Blameless Postmortems

## 1. Theoretical Foundation

### The Chaos Engineering Philosophy
**"Hope is not a strategy. The best time to discover how your system fails is when you choose to break it, not at 3 AM on a Saturday."**
Chaos Engineering is the discipline of experimenting on a system in order to build confidence in the system's capability to withstand turbulent conditions in production.
- Pioneered by Netflix (**Chaos Monkey**, Simian Army) to test AWS EC2 instance termination resilience.
- In Kubernetes: **Chaos Mesh**, LitmusChaos.

---

## 2. Conducting a Production GameDay

A **GameDay** is a scheduled team drill where engineers deliberately inject simulated failures into a staging or production environment to test resilience and team response:

### 4 Common GameDay Scenarios:
1. **Node Power Loss**: Abruptly terminate 2 worker nodes in Kubernetes. Does the cluster automatically reschedule Pods onto remaining nodes without dropping active user requests?
2. **Database Failover**: Force an Amazon RDS Multi-AZ failover. Does the application reconnect to the new primary database within 60 seconds without hanging?
3. **Network Latency Injection**: Inject 500ms packet latency and 10% packet drop using Linux `tc` (traffic control). Do downstream circuit breakers trip gracefully?
4. **API Dependency Outage**: Block outbound traffic to a third-party payment gateway or email API. Does the application degrade gracefully with clear user error messaging, or does the entire web server freeze?

---

## 3. The Blameless Postmortem (Post-Incident Review)

In modern SRE culture, **human error is considered a symptom, never the root cause**. If an engineer ran `rm -rf` on the wrong database, the system is flawed for allowing an individual human to destroy production with a single unverified command!

### The 5 Whys Root Cause Analysis Example
- *Problem*: The production database crashed for 45 minutes.
  1. **Why?** The database disk reached 100% full capacity.
  2. **Why?** A debug log file grew to 80GB overnight.
  3. **Why?** A developer enabled verbose DEBUG logging to troubleshoot a payment issue and forgot to turn it off.
  4. **Why?** There was no log rotation policy configured on that service.
  5. **Why?** There was no automated CI/CD lint check or Terraform policy enforcing log rotation on newly provisioned databases.
- **Remediation Action Item**: Implement automated Checkov policy requiring log rotation on all databases, and set up CloudWatch disk alarms at 80% capacity. (No blaming the developer!).

---

## 4. Phase 6 Milestone Completed!

🎉 **Congratulations! You have mastered Phase 6: Monitoring, Security & Reliability.**
You now possess industry-grade expertise in:
- Observability pillars (Metrics, Logs, Traces) and Google SRE Golden Signals.
- Defining SLIs, SLOs, SLAs, and managing Error Budgets.
- Writing production PromQL queries and Prometheus metric aggregations.
- Designing high-impact Grafana Dashboards as Code.
- Alertmanager routing, deduplication, grouping, and severity escalation runbooks.
- Shift-Left DevSecOps: SAST, SCA, container vulnerability scanning with Trivy.
- AWS KMS Envelope Encryption, CloudTrail audit logs, and GuardDuty threat detection.
- RTO and RPO disaster recovery strategies (Backup/Restore to Active/Active).
- Brendan Gregg's 60-second Linux performance triage methodology.
- Chaos Engineering GameDays and Blameless Postmortem retrospectives.

Next: **Phase 7 — Production Capstone Project & Career Transition (Days 81–90)**!
