# Phase 3: AWS Cloud Engineering (Days 26–40)

Cloud engineering is the foundational substrate of modern DevOps. Amazon Web Services (AWS) powers a massive share of the world's production applications. This phase covers core cloud architecture, identity management (IAM), compute (EC2), storage (EBS/S3), networking (VPC/Subnets/NAT/Gateways), observability (CloudWatch), cost governance, and security hardening.

---

## 📅 Daily Learning Index

| Day | Topic | In-Depth Learning Guide | Key Concepts |
| :--- | :--- | :--- | :--- |
| **26** | **AWS Global Infra & Shared Responsibility** | [Day 26 Guide](./day-26-aws-fundamentals-shared-responsibility.md) | Regions, AZs, Edge Locations, Shared Responsibility Model, Well-Architected Framework |
| **27** | **AWS IAM (Users, Groups, Roles & Policies)** | [Day 27 Guide](./day-27-iam-users-roles-policies.md) | Root account safety, IAM policies (JSON), Roles vs Users, AssumeRole (STS), Least Privilege |
| **28** | **AWS CLI, SDKs & Credential Hygiene** | [Day 28 Guide](./day-28-aws-cli-credentials.md) | AWS CLI v2, named profiles, SSO/OIDC credentials, metadata service (IMDSv2) |
| **29** | **Amazon EC2 & Linux Cloud Compute** | [Day 29 Guide](./day-29-ec2-linux-cloud-instances.md) | Instance families, AMIs, User Data bootstrapping, pricing models (On-Demand, Spot, RI) |
| **30** | **EC2 Security, Networking & Triage** | [Day 30 Guide](./day-30-ec2-security-troubleshooting.md) | Security Groups, System/Instance status checks, System Manager Session Manager (SSM) |
| **31** | **EBS Volumes, Snapshots & AMIs** | [Day 31 Guide](./day-31-ebs-amis-instance-storage.md) | EBS volume types (gp3, io2), snapshots, encryption (KMS), instance store ephemeral disks |
| **32** | **Amazon S3 Fundamentals** | [Day 32 Guide](./day-32-s3-fundamentals.md) | Buckets, object keys, storage classes (Standard, IA, Glacier), versioning, multipart uploads |
| **33** | **S3 Security & Static Website Hosting** | [Day 33 Guide](./day-33-s3-security-static-hosting.md) | Bucket Policies, S3 Block Public Access, CORS, CloudFront CDN integration, Origin Access Control |
| **34** | **Amazon VPC & Subnetting Architecture** | [Day 34 Guide](./day-34-vpc-fundamentals.md) | CIDR math, Public vs Private Subnets, Route Tables, ENIs, Availability Zone redundancy |
| **35** | **Internet Gateways, NAT Gateways & Egress** | [Day 35 Guide](./day-35-routing-igw-nat.md) | IGW, NAT Gateway vs NAT Instance, default routes (0.0.0.0/0), private subnet outbound egress |
| **36** | **Security Groups vs. Network ACLs (NACLs)** | [Day 36 Guide](./day-36-security-groups-network-acls.md) | Stateful Security Groups vs Stateless NACLs, ephemeral return ports, defense-in-depth |
| **37** | **Observability: CloudWatch Metrics & Logs** | [Day 37 Guide](./day-37-aws-monitoring-cloudwatch.md) | CloudWatch Logs agent, custom metric filters, CloudWatch Alarms, SNS notifications |
| **38** | **AWS Cost Optimization & Resource Tagging** | [Day 38 Guide](./day-38-aws-cost-management-tagging.md) | AWS Budgets, Cost Explorer, mandatory tag allocation, unattached EBS/EIP cleanup |
| **39** | **AWS CLI Automation & Security Audit** | [Day 39 Guide](./day-39-aws-cli-automation-security-review.md) | JMESPath `--query` expressions, dry-run flags, AWS IAM Credential Report, Security Hub |
| **40** | **AWS Mini-Project: 2-Tier VPC Architecture** | [Day 40 Guide](./day-40-aws-mini-project-review.md) | Highly available, multi-AZ VPC deployment with public bastion, private app tier, and NAT gateway |

---

## 🎯 Phase 3 Goals & Milestones
By the end of Phase 3, you should be able to:
1. Architect secure, multi-tier Virtual Private Clouds (VPCs) across multiple Availability Zones.
2. Implement strict IAM least-privilege policies and eliminate static long-lived AWS access keys using IAM Roles and IMDSv2.
3. Manage and troubleshoot compute (EC2), persistent block storage (EBS), and scalable object storage (S3).
4. Automate cloud queries using AWS CLI v2 with JMESPath filtering.
