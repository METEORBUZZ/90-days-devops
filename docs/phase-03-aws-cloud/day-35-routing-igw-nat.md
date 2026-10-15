# Day 35: Internet Gateways, NAT Gateways & VPC Routing

## 1. Theoretical Foundation

### The VPC Router & Route Tables
Every subnet in an Amazon VPC is associated with exactly one **Route Table**.
A Route Table contains rules (routes) that dictate where network traffic leaving instances in that subnet is directed:
- **Destination**: The target CIDR range (e.g. `10.0.0.0/16` for internal VPC traffic, or `0.0.0.0/0` for the entire internet).
- **Target**: The gateway, network interface, or peering connection handling the traffic (e.g. `local`, `igw-xxx`, `nat-xxx`).

---

## 2. Internet Gateway (IGW)

An **Internet Gateway (IGW)** is a horizontally scaled, redundant, and highly available VPC component that enables communication between instances in your VPC and the internet.
- Performs **One-to-One Static NAT (Network Address Translation)**: Maps the private IPv4 address of an EC2 instance to its associated Public IPv4 address when packets egress to the internet.
- Imposes zero availability risk or bandwidth bottleneck on network traffic.
- Attached directly to the VPC boundary (exactly 1 IGW per VPC).

### Public Route Table Configuration
```text
Destination         Target
-----------------------------------------
10.0.0.0/16         local               (Allows all subnets in VPC to communicate)
0.0.0.0/0           igw-0a1b2c3d4e5f    (Routes all external traffic to Internet Gateway)
```

---

## 3. Network Address Translation (NAT) Gateway

Instances running in **Private Subnets** (e.g. backend application servers, databases) must never be directly accessible from the internet. However, they still need to:
- Download security patches (`apt update && apt upgrade`).
- Pull Docker container base images.
- Connect to third-party APIs (Stripe, Twilio, SendGrid).

To facilitate this, AWS provides the **NAT Gateway**:
- **Where it lives**: Must be deployed in a **Public Subnet** and assigned a static public **Elastic IP (EIP)**.
- Performs **Source NAT (SNAT)**: Replaces the private IP of outbound packets with the NAT Gateway's Elastic IP.
- **One-Way Egress Only**: External internet actors cannot initiate a connection into instances behind a NAT Gateway!

### Private Route Table Configuration
```text
Destination         Target
-----------------------------------------
10.0.0.0/16         local
0.0.0.0/0           nat-0123456789abcdef0 (Routes all external traffic to NAT Gateway)
```

---

## 4. NAT Gateway vs. NAT Instance

| Feature | AWS Managed NAT Gateway | Self-Managed NAT Instance (EC2) |
| :--- | :--- | :--- |
| **Maintenance** | Fully managed by AWS; no OS patching or maintenance | Customer must patch Linux, configure iptables, and manage uptime |
| **High Availability** | Built-in redundancy within the AZ; auto-scales up to 100 Gbps | Single point of failure unless custom multi-AZ scripts configured |
| **Port Forwarding / Bastion** | Not supported (pure outbound egress only) | Supported (can act as dual NAT + Bastion) |
| **Cost** | ~$32/month base per AZ + data processing charges | Cost of small EC2 instance (e.g. t4g.nano ~$3/month) |

---

## 5. Multi-AZ NAT Gateway Architecture for Production

Because a NAT Gateway is bound to a single Availability Zone:
- **Dev/Test Environments**: Deploy 1 NAT Gateway in AZ-A to save costs (~$32/mo).
- **Mission-Critical Production**: Deploy **1 NAT Gateway per Availability Zone**! If AZ-A experiences a data center outage, private subnets in AZ-B continue egressing traffic through NAT Gateway B without interruption.

```
Region: us-east-1
+------------------------------------+    +------------------------------------+
|  AZ-A                              |    |  AZ-B                              |
|  [ Public Subnet A ]               |    |  [ Public Subnet B ]               |
|  [ NAT Gateway A (EIP 1) ]         |    |  [ NAT Gateway B (EIP 2) ]         |
|                 ^                  |    |                 ^                  |
|                 |                  |    |                 |                  |
|  [ Private Subnet A ]              |    |  [ Private Subnet B ]              |
|  [ App Server 1 ]                  |    |  [ App Server 2 ]                  |
+------------------------------------+    +------------------------------------+
```

---

## 6. Interview & Review Questions
1. **Can an EC2 instance in a private subnet receive incoming connections directly from the internet through a NAT Gateway?**
   - *Answer*: No. A NAT Gateway operates as a one-way Source NAT (SNAT). It only allows instances inside the private subnet to initiate outbound connections to the internet and returns the corresponding response packets. It does not accept inbound connection requests from external hosts.
2. **What happens if a production VPC with private workloads in 3 AZs only has 1 NAT Gateway deployed in AZ-1, and AZ-1 goes down?**
   - *Answer*: All instances in AZ-2 and AZ-3 that rely on that single NAT Gateway lose all outbound internet connectivity (breaking third-party API calls, updates, and external dependencies). To prevent this single point of failure in production, one NAT Gateway should be provisioned in each active AZ.
