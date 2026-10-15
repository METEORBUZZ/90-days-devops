# Day 81: Production Capstone — System Requirements, Architecture Design & Cost Estimation

## 1. Project Overview & Business Case

The capstone project represents a complete, production-ready cloud-native SaaS workload: **CloudOrders API**.
- **Business Need**: High-availability e-commerce order ingestion API requiring sub-100ms response times, zero data loss, 99.9% uptime SLO, and automated recovery from data center outages.

---

## 2. High-Level System Architecture Diagram

```
                                  [ Global Internet Users ]
                                              |
                                              v
                              [ Amazon Route 53 (DNS Failover) ]
                                              |
                                              v
                       [ AWS Web Application Firewall (AWS WAF) ]
                                              |
                                              v
                        [ AWS Application Load Balancer (ALB) ]
                                              |
                        (Multi-AZ TLS Ingress Routing over 443)
                                              |
        +-------------------------------------+-------------------------------------+
        |                                                                           |
        v (ap-south-1a)                                                             v (ap-south-1b)
+------------------------------------+                     +------------------------------------+
|  Public Subnet A                   |                     |  Public Subnet B                   |
|  [ NAT Gateway A (EIP) ]           |                     |  [ NAT Gateway B (EIP) ]           |
+------------------------------------+                     +------------------------------------+
        |                                                                           |
        v                                                                           v
+------------------------------------+                     +------------------------------------+
|  Private App Subnet A              |                     |  Private App Subnet B              |
|  [ Amazon EKS Worker Node 1 ]      |                     |  [ Amazon EKS Worker Node 2 ]      |
|  - Pod: order-api (v1.4)           |                     |  - Pod: order-api (v1.4)           |
|  - HPA (Autoscaling 2 to 10 pods)  |                     |  - HPA (Autoscaling 2 to 10 pods)  |
+------------------------------------+                     +------------------------------------+
        \                                                                           /
         +-------------------------------------+-----------------------------------+
                                               |
                                               v
                        +-----------------------------------------------+
                        |  Private Database Subnets (Multi-AZ)          |
                        |  [ Amazon RDS PostgreSQL (Primary - AZ-A) ]   |
                        |                      | (Sync Replication)     |
                        |  [ Amazon RDS PostgreSQL (Standby - AZ-B) ]   |
                        +-----------------------------------------------+
```

---

## 3. Non-Functional Requirements & SLOs

- **Availability SLO**: 99.9% uptime over a 30-day rolling window (< 43.8 minutes allowable downtime).
- **Latency Target**: p95 latency < 150ms, p99 latency < 350ms.
- **RTO (Recovery Time Objective)**: < 15 minutes in case of complete single-AZ failure.
- **RPO (Recovery Point Objective)**: < 1 minute (achieved via Amazon RDS Multi-AZ synchronous replication).
- **Security Compliance**: CIS AWS Foundations Benchmark, zero public database endpoints, all secrets managed via AWS Secrets Manager with IAM OIDC authentication.

---

## 4. Infrastructure Cost Estimation (AWS Pricing Calculator)

Monthly cost estimate for high-availability production baseline in `ap-south-1` (Mumbai):

| Resource | Specification | Quantity | Estimated Monthly Cost |
| :--- | :--- | :--- | :--- |
| **Amazon EKS Cluster** | Managed Control Plane ($0.10/hr) | 1 | ~$73.00 |
| **EC2 Worker Nodes** | `t4g.medium` (2 vCPU, 4GB RAM, ARM Graviton) | 2 | ~$48.00 |
| **Amazon RDS PostgreSQL** | `db.t4g.medium` Multi-AZ (100GB gp3 SSD) | 1 | ~$115.00 |
| **AWS NAT Gateways** | Managed NAT Gateway ($0.045/hr + data) | 2 | ~$65.00 |
| **Application Load Balancer** | ALB (L7 HTTP/HTTPS ingress + LCU charges) | 1 | ~$22.00 |
| **Amazon S3 & ECR** | Storage + Container Registry | 50 GB | ~$3.00 |
| **Total Estimated Spend** | | | **~$326.00 / month** |

---

## 5. Review Questions
1. **Why does this architecture deploy NAT Gateways and EKS Nodes in both `ap-south-1a` and `ap-south-1b`?**
   - *Answer*: To eliminate single points of failure. If an entire physical data center or Availability Zone experiences a catastrophic power outage or fiber cut, the surviving AZ automatically handles 100% of the traffic without service disruption.
2. **How does synchronous Multi-AZ RDS replication satisfy an RPO of under 1 minute?**
   - *Answer*: Amazon RDS Multi-AZ synchronously writes every database transaction to both the primary and standby DB instances before returning success to the application. If the primary instance fails, failover to the standby occurs with zero data loss ($RPO = 0$).
