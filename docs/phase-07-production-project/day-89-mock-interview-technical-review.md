# Day 89: Senior DevOps & SRE Mock Technical Interview

## 1. System Design Interview Question

### The Challenge:
> *"Design a highly available, multi-region web platform on AWS that serves 50,000 requests per second with a 99.99% availability SLA and sub-100ms latency globally."*

### The Model Senior Answer Architecture:
1. **Edge Layer**:
   - **Amazon Route 53**: Latency-based routing with automated health check failover across two primary regions (`us-east-1` and `eu-central-1`).
   - **Amazon CloudFront**: Caches static content at 400+ Edge PoPs worldwide; terminates TLS close to users; protected by AWS WAF and AWS Shield Advanced against DDoS attacks.
2. **Compute & Ingress Layer**:
   - **AWS Application Load Balancer (ALB)** in each region routing traffic to **Amazon EKS** clusters.
   - Kubernetes **Horizontal Pod Autoscaler (HPA)** paired with **Karpenter** for rapid dynamic node provisioning.
3. **Data Layer**:
   - **Amazon Aurora Global Database**: Multi-region database with sub-second replication latency across regions. Regional local read replicas handle read traffic with zero cross-region latency.
   - **Amazon ElastiCache Redis**: In-memory caching layer to absorb 85% of read queries before hitting Aurora.
4. **Disaster Recovery**:
   - Multi-Region Active/Active architecture achieving $RTO < 2\text{ minutes}$ and $RPO < 1\text{ second}$.

---

## 2. Live Troubleshooting Interview Scenario

### The Challenge:
> *"It's 2 AM. An alert fires: Our main API is returning HTTP 502 Bad Gateway to 30% of incoming users. Walk me through your first 5 minutes of investigation."*

### The Model Senior Answer:
1. **Minute 1: Assess Blast Radius & Freeze Mutations**:
   - Check status page, real-time traffic volume, and recent deployment history. If a deployment happened in the last 15 minutes, prepare for an immediate rollback.
2. **Minute 2: Isolate the Gateway Layer**:
   - A `502 Bad Gateway` means the Reverse Proxy (ALB or Nginx Ingress) reached its upstream target, but the backend application closed the connection abruptly or sent invalid HTTP bytes.
   - Check ALB target health: `aws elbv2 describe-target-health`. Are backend targets reporting `Unhealthy`?
3. **Minute 3: Inspect Kubernetes Fleet & Pod Logs**:
   - `kubectl get pods -n prod -o wide`: Check for Pod restarts or nodes in `NotReady` state.
   - `kubectl logs -l app=api -n prod --tail=100 | grep -i -E "(oom|panic|timeout|db)"`: Identify whether threads are crashing or database connection pools are saturated.
4. **Minute 4: Mitigate**:
   - If Pods are crashing due to memory, scale deployment memory or increase replica count. If database is choked with slow queries, kill blocking queries.
5. **Minute 5: Communicate**:
   - Post an initial status update to the incident channel and update public status page with acknowledgment.

---

## 3. Behavioral Questions (The STAR Method)

Use the **Situation, Task, Action, Result** framework:

### Question: "Tell me about a time when you caused a production outage."
- **Situation**: During a scheduled database maintenance window, I applied a Terraform change to update a PostgreSQL parameter group.
- **Task**: The goal was to increase the max connection limit from 500 to 1,000.
- **Action**: A dependent parameter required an immediate instance reboot that wasn't highlighted in the plan output, causing an unexpected 4-minute database restart. I immediately owned the issue in the incident channel, verified health checks passed upon reboot, and confirmed the service recovered.
- **Result**: Following the outage, I authored a blameless postmortem and added pre-apply CI policy checks to flag any Terraform resource attribute requiring static reboots, preventing future unplanned restarts.

---

## 4. Key Takeaways & Review
- System design interviews test your ability to balance cost, performance, and reliability trade-offs.
- In troubleshooting interviews, structured communication and hypothesis-driven isolation matter more than random guessing.
- In behavioral interviews, taking ownership and explaining systemic prevention highlights true senior engineering maturity.
