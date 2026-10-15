# Day 29: Amazon EC2 Architecture, Instance Types & Lifecycle

## 1. Theoretical Foundation

### What is Amazon EC2?
Amazon Elastic Compute Cloud (EC2) provides resizable, on-demand virtual compute capacity in the cloud. An EC2 instance is a virtual machine running on AWS's customized KVM-based hypervisor (the **AWS Nitro System**).

### EC2 Instance Families & Naming Convention
Instance names follow the pattern: `[Family][Generation][Capabilities].[Size]`
- Example: **`c7g.xlarge`**
  - **`c`**: Instance Family (Compute Optimized).
  - **`7`**: Generation (7th Generation hardware).
  - **`g`**: Capabilities (`g` = AWS Graviton ARM processor, `i` = Intel, `a` = AMD, `n` = Network enhanced).
  - **`xlarge`**: Size (determines vCPU count, RAM, network bandwidth, and EBS throughput).

| Family | Name | Best DevOps Workloads |
| :--- | :--- | :--- |
| **General Purpose (`t4g`, `m6i`, `m7g`)** | Balanced compute, memory, and networking | Web servers, microservices, dev environments |
| **Compute Optimized (`c6i`, `c7g`)** | High vCPU-to-memory ratio | CI/CD build nodes, batch processing, video encoding |
| **Memory Optimized (`r6i`, `r7g`)** | High memory-to-vCPU ratio | Redis/Memcached caches, high-throughput databases |
| **Storage Optimized (`i3en`, `im4gn`)** | High sequential read/write NVMe SSDs | Cassandra, Elasticsearch/OpenSearch, Kafka clusters |

---

## 2. EC2 Purchasing & Pricing Models

1. **On-Demand**: Pay per second with no long-term commitment. Highest hourly cost. Ideal for irregular, short-term, or unpredictable workloads.
2. **Reserved Instances (RI) & Savings Plans**: Commit to consistent compute usage for 1 or 3 years in exchange for up to **72% discount**. Standard for steady-state production databases and baseline cluster nodes.
3. **Spot Instances**: Bid on unused EC2 capacity with up to **90% discount**.
   - *Catch*: AWS can reclaim the instance with only a **2-minute notification** if on-demand demand spikes!
   - *DevOps Use Case*: Stateless Kubernetes worker nodes, CI/CD test runners, batch ML training.

---

## 3. Bootstrapping with EC2 User Data

**User Data** is a shell script passed to the instance at launch. The `cloud-init` service executes this script automatically with `root` privileges during the very first boot cycle.

### Production User Data Script Example
```bash
#!/usr/bin/env bash
set -euo pipefail

# Update system packages
apt-get update -y
apt-get install -y nginx curl jq

# Configure custom landing page with instance metadata
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id || echo "local")
cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head><title>Production Node</title></head>
<body>
  <h1>Welcome to DevOps Fleet</h1>
  <p>Instance ID: ${INSTANCE_ID}</p>
</body>
</html>
EOF

# Ensure Nginx starts on boot
systemctl enable --now nginx
```

---

## 4. Launching an EC2 Instance via AWS CLI

```bash
# 1. Query latest official Ubuntu 24.04 LTS AMI ID in current region
AMI_ID=$(aws ssm get-parameter \
  --name "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id" \
  --query "Parameter.Value" \
  --output text)

# 2. Launch t3.micro instance with tags and user-data
aws ec2 run-instances \
  --image-id "$AMI_ID" \
  --instance-type t3.micro \
  --key-name "my-devops-key" \
  --security-group-ids "sg-0123456789abcdef0" \
  --subnet-id "subnet-0123456789abcdef0" \
  --user-data file://userdata.sh \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=web-prod-01},{Key=Environment,Value=Production}]'
```

---

## 5. Interview & Review Questions
1. **What is the difference between stopping and terminating an EC2 instance?**
   - *Answer*: Stopping an instance powers down the VM; root EBS volumes remain preserved (you only pay for EBS storage, not compute). Terminating an instance destroys the virtual machine and automatically deletes root EBS volumes configured with `DeleteOnTermination=true`, releasing all compute and storage allocations permanently.
2. **How does AWS Spot Instance termination work and how do resilient architectures handle it?**
   - *Answer*: AWS delivers an Amazon EventBridge event and sends a termination notice to the instance metadata endpoint 2 minutes before reclamation. Resilient architectures (like AWS Auto Scaling Groups or Kubernetes with Karpenter) listen for the notice, cordon the node, drain running Pods to other nodes, and gracefully shut down workloads before the instance terminates.
