# Day 38: AWS Cost Management, FinOps & Resource Tagging Strategy

## 1. Theoretical Foundation

### The FinOps Discipline in DevOps
FinOps (Cloud Financial Operations) is the cultural practice of bringing financial accountability to the variable spend model of cloud computing.
In traditional on-premises data centers, procurement was a capital expense (CapEx) requiring months of approval. In AWS, any developer or Terraform script can spin up expensive resources in seconds (OpEx). Without governance, monthly AWS bills quickly spiral out of control.

---

## 2. Mandatory Resource Tagging Strategies

Tags are key-value labels assigned to AWS resources. They are the backbone of cost allocation, automation, and security audits.

### Standard DevOps Tag Taxonomy
Every provisioned AWS resource (EC2, S3, RDS, VPC) must have these standard tags:
1. `Environment`: `production`, `staging`, `development`, `sandbox`.
2. `Project` / `Application`: `checkout-service`, `data-warehouse`.
3. `Owner` / `Team`: `payments-team@company.com`, `sre-team`.
4. `CostCenter` / `BillingCode`: `CC-4012`.
5. `ManagedBy`: `terraform`, `pulumi`, `cloudformation` (Never leave unmanaged manual resources!).

```bash
# Applying tags via AWS CLI
aws ec2 create-tags \
  --resources i-0123456789abcdef0 \
  --tags Key=Environment,Value=Production Key=Owner,Value=payments-team Key=ManagedBy,Value=terraform
```

### Activating Cost Allocation Tags
Creating tags is not enough. You must navigate to **AWS Billing Console > Cost Allocation Tags** and click **Activate** so AWS includes those tags in AWS Cost Explorer and Cost & Usage Reports (CUR).

---

## 3. Detecting Cloud Waste & "Zombie" Resources

The top 5 sources of wasted cloud spend in AWS environments:

### 1. Unattached EBS Volumes
When an EC2 instance is terminated without deleting attached data disks, the EBS volume continues accruing hourly charges forever:
```bash
# Find all unattached (available) EBS volumes across the region
aws ec2 describe-volumes \
  --filters Name=status,Values=available \
  --query "Volumes[].[VolumeId, Size, CreateTime]" \
  --output table
```

### 2. Orphaned Elastic IP (EIP) Addresses
AWS does **not** charge for Elastic IPs actively attached to running EC2 instances. However, AWS **charges an hourly penalty for allocated Elastic IPs that are unattached**!
```bash
# Find all unassociated Elastic IPs
aws ec2 describe-addresses \
  --query "Addresses[?AssociationId==null].[PublicIp, AllocationId]" \
  --output table
```

### 3. Stale EBS Snapshots
Snapshots of decommissioned databases or test instances from years ago.

### 4. Over-Provisioned EC2 / RDS Instances
Instances running at 2% average CPU utilization throughout the week. Downsize (e.g. from `m5.2xlarge` to `t4g.medium`).

---

## 4. AWS Budgets & Anomaly Detection

### Setting Up an AWS Budget Alert
Set up automated billing guardrails before launching workloads:
```bash
# Create a zero-spend or $50 monthly threshold budget with email alerts
aws budgets create-budget \
  --account-id 123456789012 \
  --budget file://monthly-budget.json \
  --notifications-with-subscribers file://budget-notifications.json
```

### AWS Cost Anomaly Detection
An AI/ML-driven service that continuously monitors billing patterns. If a misconfigured script or hacked API key spawns 50 GPU instances at midnight, Anomaly Detection sends an emergency alert within hours before you incur thousands of dollars in debt.

---

## 5. Interview & Review Questions
1. **Does AWS charge for an Elastic IP address when it is attached to a running EC2 instance? What about when it is unattached?**
   - *Answer*: AWS allows one free Elastic IP per running EC2 instance to encourage public IP conservation. If an Elastic IP is allocated to your account but is unattached to any running instance, AWS charges an hourly fee to prevent IP address hoarding.
2. **What is the purpose of Cost Allocation Tags in AWS?**
   - *Answer*: Cost Allocation Tags enable organizations to categorize and track AWS costs at a granular level. Once activated in the billing console, financial and engineering teams can break down monthly spend by department, project, application, or environment in AWS Cost Explorer.
