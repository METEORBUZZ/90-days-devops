# Day 78: Backups, Disaster Recovery Strategies & RTO/RPO

## 1. Theoretical Foundation

### The Core DR Metrics: RTO vs. RPO
Every enterprise business continuity plan is anchored by two critical metrics:

```
<--- RPO (Data Loss Window) ---> [ DISASTER OCCURS ] <--- RTO (Downtime Window) --->
|-------------------------------|                    |------------------------------|
Last Backup Taken                Database Crashes     System Fully Restored
(Target: e.g. 15 mins)                                (Target: e.g. 1 hour)
```

1. **RPO (Recovery Point Objective)**: The **maximum acceptable age of data lost** when an outage strikes.
   - *Example*: If your database backup runs every night at midnight, and the system crashes at 11:59 PM, your maximum data loss is 24 hours ($RPO = 24h$). If business requires $RPO < 15m$, you must use continuous replication or 15-minute transaction log snapshots.
2. **RTO (Recovery Time Objective)**: The **maximum acceptable downtime** before the system is brought back online and healthy.
   - *Example*: If an enterprise takes 4 hours to provision new infrastructure, restore database dumps, and redirect DNS, the $RTO = 4h$.

---

## 2. The 4 AWS Disaster Recovery Strategies

As RTO and RPO decrease toward zero, implementation cost increases exponentially:

```
[ Lower Cost / Higher Downtime ]                                [ Higher Cost / Zero Downtime ]
Backup & Restore ---------> Pilot Light ---------> Warm Standby ---------> Multi-Region Active/Active
(RTO: Hours/Days)          (RTO: 10s of mins)     (RTO: Minutes)          (RTO: Real-Time / Zero)
(RPO: 24 Hours)            (RPO: Minutes)         (RPO: Seconds)          (RPO: Zero)
```

| DR Strategy | Architecture | Cost | RTO | RPO |
| :--- | :--- | :--- | :--- | :--- |
| **1. Backup & Restore** | Data backed up to S3 in secondary region. Infrastructure provisioned from scratch via Terraform only when disaster strikes. | $ | Hours to Days | Hours to 24h |
| **2. Pilot Light** | Core data replicated continuously to secondary region (e.g. read replica database). Compute servers are stopped (or minimal AMIs ready); scaled up when disaster occurs. | $$ | 10–30 Minutes | Minutes |
| **3. Warm Standby** | Scaled-down version of full environment running 24/7 in secondary region. Handles minimal traffic; rapidly scaled up during failover. | $$$ | Minutes | Seconds |
| **4. Multi-Region Active/Active**| Full production capacity running simultaneously in 2+ geographic regions. Global Route 53 routes traffic to nearest healthy region. | $$$$ | Real-time (Zero) | Zero |

---

## 3. The Fallacy of Untested Backups
**"An untested backup is not a backup; it is merely an unverified hope."**
- In modern DevOps, automated CI/CD pipelines run weekly restore drills:
  1. Automated job takes a database snapshot.
  2. Provisions a temporary isolated test database instance.
  3. Restores the snapshot.
  4. Runs integrity validation queries against the restored data.
  5. Tears down the temporary instance.
  6. Sends a green health report to the compliance channel.

---

## 4. Interview & Review Questions
1. **Explain the difference between RTO and RPO with an example.**
   - *Answer*: RTO (Recovery Time Objective) is the maximum acceptable duration of system downtime to restore operations following an incident. RPO (Recovery Point Objective) is the maximum acceptable amount of data loss measured in time between the disaster and the most recent valid backup.
2. **How does a "Pilot Light" disaster recovery strategy differ from a "Warm Standby" strategy?**
   - *Answer*: In a Pilot Light strategy, only the core critical data storage (like databases) is continuously synchronized to the secondary disaster recovery site, while compute servers remain un-provisioned or in cold standby until failover. In a Warm Standby strategy, a fully functional, scaled-down version of the entire compute and networking stack runs continuously in the secondary region, allowing faster failover.
