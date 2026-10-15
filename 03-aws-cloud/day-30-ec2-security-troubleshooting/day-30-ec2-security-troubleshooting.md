# Day 30: EC2 Security Groups, Status Checks & Troubleshooting Triage

## 1. Theoretical Foundation

### Security Groups (Virtual Firewalls)
A **Security Group** acts as a virtual firewall for your EC2 instances to control incoming and outgoing network traffic at the Elastic Network Interface (ENI) level.
Key Characteristics:
- **Stateful**: If you send an outbound request from your instance, the response traffic for that request is allowed in automatically, regardless of inbound security group rules!
- **Default Deny**: By default, all inbound traffic is blocked. You must explicitly create **Allow** rules (Security Groups do **not** support explicit Deny rules; use NACLs for Deny).
- **Security Group Referencing**: Instead of allowing an IP address range, Security Group A can allow inbound traffic originating from any instance associated with Security Group B!

```
[ Internet ] ---> [ ALB (SG: alb-sg) ] ---> [ EC2 App (SG: app-sg) ] ---> [ RDS (SG: rds-sg) ]
                       Allow: 80, 443              Allow: 8080 from               Allow: 5432 from
                       from: 0.0.0.0/0             alb-sg                         app-sg
```

---

## 2. EC2 Status Checks: System vs. Instance

AWS performs two automated diagnostic status checks every minute:

| Status Check | What it Tests | Root Causes of Failure | How to Resolve |
| :--- | :--- | :--- | :--- |
| **System Status Check** (`1/2`) | AWS hardware, power, physical host hypervisor, network switch | Physical hardware defect in AWS rack | Stop and Start the instance (forces AWS to launch your instance on a different healthy physical host rack). |
| **Instance Status Check** (`1/2`) | Guest Operating System, file system corruption, kernel panic, misconfigured network | Corrupt `/etc/fstab`, kernel crash, memory exhaustion (OOM), exhausted disk | Reboot instance; if unresponsive, detach root EBS volume, attach to rescue instance, fix config file, and reattach. |

---

## 3. Production Troubleshooting Playbook: Unreachable EC2 Instance

When an engineer reports "I cannot SSH into the EC2 instance":

```bash
# 1. Check Status Checks via AWS CLI
aws ec2 describe-instance-status --instance-ids i-0123456789abcdef0

# 2. Check Security Group Rules
aws ec2 describe-security-groups --group-ids sg-0123456789abcdef0

# 3. View the Instance System Log (Console Output / Kernel Dmesg)
aws ec2 get-console-output --instance-id i-0123456789abcdef0 --output text

# 4. View Instance Screenshot (Detect Windows BSOD or Linux kernel panic)
aws ec2 get-console-screenshot --instance-id i-0123456789abcdef0
```

### Common Failure Points Checklist
1. **Security Group**: Is port 22 open from your current public IP address? (Never leave `0.0.0.0/0` open to port 22 in production!).
2. **Subnet Route Table**: Is the instance in a public subnet with a route pointing to an Internet Gateway (`0.0.0.0/0 -> igw-xxx`)?
3. **Public IP**: Does the instance have an allocated Public IPv4 or Elastic IP?
4. **SSH Key Pair**: Are you specifying the correct private key (`ssh -i ~/.ssh/key.pem`)?
5. **Username**: Did you use the correct default OS user?
   - Ubuntu: `ubuntu`
   - Amazon Linux: `ec2-user`
   - Debian: `admin`
   - RHEL / CentOS: `ec2-user` or `root`

---

## 4. Modern Alternative: AWS Systems Manager (SSM) Session Manager

In modern enterprise security, **port 22 is completely closed**, and instances do not have public IPs or bastion hosts.
Engineers connect securely via **AWS Systems Manager (SSM) Session Manager**:
- No open inbound ports required in Security Groups!
- No SSH keys to distribute, rotate, or lose.
- All session commands and keystrokes are audited in AWS CloudTrail and S3 logs.
- Access is governed purely by IAM policies.

```bash
# Start an interactive shell session over AWS SSM (no port 22 needed!)
aws ssm start-session --target i-0123456789abcdef0
```

---

## 5. Interview & Review Questions
1. **What is the difference between a System Status Check failure and an Instance Status Check failure?**
   - *Answer*: System status check failures indicate underlying AWS hardware or hypervisor problems requiring an instance Stop/Start to migrate to a new physical host. Instance status check failures indicate operating system, kernel, or software boot configuration problems inside the customer-managed VM.
2. **Why is AWS SSM Session Manager preferred over traditional SSH with Bastion hosts?**
   - *Answer*: SSM Session Manager operates outbound via an HTTPS agent tunnel (`443`), eliminating the need to expose port 22 to the internet, run costly bastion EC2 instances, manage SSH key pairs across team members, and provides centralized IAM RBAC with full session audit logging.
