# Day 50: Continuous Delivery vs. Deployment & Modern Release Strategies

## 1. Theoretical Foundation

### Continuous Delivery vs. Continuous Deployment
- **Continuous Delivery**: Code passes all automated CI stages (testing, building, security scans) and is packaged as a release candidate ready for deployment. The promotion to Production requires an explicit manual click or approval.
- **Continuous Deployment**: Every commit that successfully passes the automated pipeline is automatically deployed directly to Production with zero human intervention.

```
+--------------------+   +--------------------+   +--------------------+   +--------------------+
|  Code & Commit     |-->|  Build & Test (CI) |-->|  Deploy to Staging |-->| Deploy to Prod (CD)|
+--------------------+   +--------------------+   +--------------------+   +--------------------+
                                                                                 ^
                                          Continuous Delivery: [ Manual Approval Gate ]
                                          Continuous Deployment: [ 100% Fully Automated ]
```

---

## 2. Production Deployment Strategies Comparison

| Strategy | Mechanism | Downtime | Rollback Speed | Cost |
| :--- | :--- | :--- | :--- | :--- |
| **Recreate** | Terminate all version A instances; then boot version B instances. | **YES (Downtime)** | Slow (must re-deploy version A) | Lowest (zero duplicate compute) |
| **Rolling Update** | Incrementally replace instances running version A with version B one by one. | **Zero** | Moderate (reverse rolling rollout) | Low (no duplicate infrastructure) |
| **Blue / Green** | Run two identical environments. Deploy version B to Green. Run smoke tests. Instantly switch router/ALB traffic from Blue to Green. | **Zero** | **Instant (Seconds)** (Switch router back to Blue) | High (2x compute during deployment) |
| **Canary** | Route 5%–10% of real user traffic to version B. Monitor error rates. If healthy, gradually ramp up to 100%. | **Zero** | Fast (Drop canary route) | Low to Moderate |

---

## 3. Deep Dive: Blue/Green Deployment Architecture

```
                                  [ Internet Traffic ]
                                           |
                                           v
                          [ Application Load Balancer / Route 53 ]
                                   /             \
                   (Active 100%)  /               \ (Standby 0% - Smoke Tests)
                                 v                 v
                   +-------------------+     +-------------------+
                   |  BLUE Environment |     | GREEN Environment |
                   |  (Version 1.0.0)  |     | (Version 2.0.0)   |
                   +-------------------+     +-------------------+
```

### Execution Steps:
1. Production currently runs on **Blue**.
2. Deploy new version 2.0.0 to the isolated **Green** fleet.
3. Run automated internal end-to-end smoke tests against Green's private test endpoint.
4. Update the Load Balancer target group listener: **instantly shift 100% user traffic to Green**.
5. Keep Blue on standby for 1 hour. If unexpected errors occur, instantly flip the listener back to Blue (instant rollback with zero data loss).
6. Decommission old Blue instances.

---

## 4. Deep Dive: Canary Deployment Strategy

Used by high-scale companies (Netflix, Amazon, Google) to minimize the blast radius of unexpected edge-case bugs:

```
Step 1: 95% traffic -> v1.0.0  |  5% traffic -> v2.0.0 (Canary)
        [ Monitor Prometheus 5xx error rate and latency metrics for 15 minutes ]

Step 2: If error rate < 0.01%:
        75% traffic -> v1.0.0  |  25% traffic -> v2.0.0

Step 3: 100% traffic -> v2.0.0 (Full Promotion)
```

---

## 5. Interview & Review Questions
1. **What is the primary advantage of a Blue/Green deployment over a Rolling Update?**
   - *Answer*: Instantaneous rollback capability. If a critical bug is discovered after cutover, you can redirect the load balancer back to the intact Blue environment within seconds, whereas rolling back a Rolling Update requires waiting for pods/instances to incrementally redeploy.
2. **What is a "Canary" deployment and what prevents it from degrading user experience?**
   - *Answer*: A Canary deployment exposes a tiny percentage of live user traffic (e.g. 2–5%) to the new software release while the remaining 95% uses the stable release. Real-time metric monitoring (error rate, p99 latency) automatically halts the rollout and diverts users back if anomalies are detected, restricting the failure blast radius to a tiny fraction of users.
