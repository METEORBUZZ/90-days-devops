# Day 31: Amazon EBS Volumes, Snapshots & AMIs

## 1. Theoretical Foundation

### Block Storage vs. Object Storage vs. File Storage
- **Block Storage (Amazon EBS)**: Network-attached virtual hard drive. Raw unformatted blocks of storage attached to a single EC2 instance at a time (like an external SSD). High throughput, low latency. Ideal for databases, operating systems, and root disks.
- **Object Storage (Amazon S3)**: Web-accessible key-value data lake. Objects accessed via REST API. Infinite scale, 99.999999999% durability.
- **File Storage (Amazon EFS / FSx)**: Shared POSIX-compliant network filesystem (NFS) mounted concurrently across hundreds of EC2 instances and Kubernetes Pods.

---

## 2. Amazon EBS Volume Types

| Volume Type | Use Case | Baseline Performance | Cost |
| :--- | :--- | :--- | :--- |
| **`gp3` (General Purpose SSD)** | Default for web servers, dev/test, boot volumes | 3,000 IOPS and 125 MB/s baseline included; scale independently of disk size | ⭐ Lowest SSD cost (20% cheaper than gp2) |
| **`gp2` (Legacy SSD)** | Older default boot volume | Performance tied to volume size (3 IOPS per GB burstable) | Deprecated; migrate to gp3 |
| **`io2` / `io2 Block Express`** | Mission-critical low-latency databases (Oracle, SAP HANA, SQL Server) | Up to 256,000 IOPS and 4,000 MB/s throughput; 99.999% durability | High performance / high cost |
| **`st1` (Throughput Optimized HDD)** | Big Data, data warehouses, log processing | Magnetic disk, sequential reads | Low |
| **`sc1` (Cold HDD)** | Lowest cost magnetic storage for infrequently accessed file archives | Sequential magnetic reads | Lowest |

---

## 3. EBS Snapshots & Incremental Backups

An **EBS Snapshot** is a point-in-time, incremental backup of an EBS volume stored redundantly across multiple Availability Zones inside Amazon S3 (managed under the hood by AWS).

```
Day 1: 10GB written  -----> Snapshot 1: [ 10GB stored in S3 ]
Day 2: 2GB changed   -----> Snapshot 2: [ 2GB delta stored in S3 ] (Points to unchanged Day 1 blocks)
Day 3: 1GB changed   -----> Snapshot 3: [ 1GB delta stored in S3 ]
```
- **Incremental Billing**: You only pay for the newly changed blocks in subsequent snapshots!
- **Deletion Safety**: Deleting Snapshot 1 does **not** corrupt Snapshot 2 or 3; AWS automatically migrates data blocks referenced by surviving snapshots.

```bash
# Create an EBS snapshot via AWS CLI
aws ec2 create-snapshot \
  --volume-id vol-0123456789abcdef0 \
  --description "Daily backup for prod database" \
  --tag-specifications 'ResourceType=snapshot,Tags=[{Key=Environment,Value=Production}]'
```

---

## 4. Amazon Machine Images (AMIs)

An **AMI (Amazon Machine Image)** is a packaged blueprint containing:
1. A root volume snapshot (containing the operating system, installed software packages, and configurations).
2. Launch permissions (who can launch the AMI: private, specific account IDs, or public).
3. Block device mappings (specifying volumes to attach when instances boot).

### Creating Custom Golden AMIs (HashiCorp Packer Workflow)
In enterprise DevOps, instances are launched from standardized **Golden AMIs** pre-baked with security agents, hardening benchmarks (CIS), and log collectors:
```bash
# Create an AMI from an existing running or stopped EC2 instance
aws ec2 create-image \
  --instance-id i-0123456789abcdef0 \
  --name "golden-ubuntu-2404-v1.0" \
  --description "Hardened CIS baseline with docker and cloudwatch agent" \
  --no-reboot
```

---

## 5. Instance Store (Ephemeral Storage) vs. EBS

Some EC2 instance types include **Instance Store** disks (physically attached directly to the host server rack hardware):
- **Performance**: Extremely fast NVMe I/O (millions of IOPS, zero network latency).
- **Caveat**: **Ephemeral (Temporary)**. If the instance is stopped, crashes, or the underlying host hardware fails, **all data on the instance store is permanently lost**!
- *DevOps Use Case*: Redis cache, temporary buffer files, Kafka replicate partitions.

---

## 6. Interview & Review Questions
1. **Why should you migrate existing EC2 volumes from `gp2` to `gp3`?**
   - *Answer*: `gp3` provides 20% lower cost per GB than `gp2` and delivers a baseline of 3,000 IOPS and 125 MB/s regardless of volume size. In `gp2`, small disks (e.g. 20GB) had only 60 IOPS baseline, forcing engineers to over-provision disk size just to get performance.
2. **Can you attach an EBS volume to an EC2 instance in a different Availability Zone?**
   - *Answer*: No. Standard EBS volumes are AZ-locked; a volume in `us-east-1a` cannot be attached directly to an EC2 instance running in `us-east-1b`. To move data across AZs, take an EBS snapshot (stored globally in S3 for that region) and create a new volume from that snapshot in the target AZ.
