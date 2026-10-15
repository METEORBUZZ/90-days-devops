# Day 34: Amazon VPC Architecture, CIDR & Subnetting

## 1. Theoretical Foundation

### What is an Amazon VPC?
An **Amazon Virtual Private Cloud (VPC)** is a logically isolated virtual network dedicated to your AWS account within a single Region. It gives you complete control over:
- IP address ranges (CIDR blocks).
- Subnets (subdivided IP segments mapped to specific Availability Zones).
- Route tables and network gateways.
- Network security boundaries (Security Groups and NACLs).

---

## 2. CIDR (Classless Inter-Domain Routing) Math for Cloud Architects

AWS VPC CIDR blocks must be between `/16` (65,536 IPs) and `/28` (16 IPs).
RFC 1918 private IP blocks are standard:
- `10.0.0.0/16` (Most popular for corporate cloud networks)
- `172.16.0.0/16`
- `192.168.0.0/16`

### Calculating Subnets
Given a VPC with CIDR `10.0.0.0/16`:
- **Subnet 1 (Public AZ-A)**: `10.0.1.0/24` (256 addresses)
- **Subnet 2 (Public AZ-B)**: `10.0.2.0/24` (256 addresses)
- **Subnet 3 (Private App AZ-A)**: `10.0.10.0/24` (256 addresses)
- **Subnet 4 (Private App AZ-B)**: `10.0.20.0/24` (256 addresses)
- **Subnet 5 (Private DB AZ-A)**: `10.0.100.0/24` (256 addresses)
- **Subnet 6 (Private DB AZ-B)**: `10.0.200.0/24` (256 addresses)

### The 5 Reserved IP Addresses in Every AWS Subnet
In every AWS subnet, **5 IP addresses are reserved by AWS and cannot be assigned to instances**:
For subnet `10.0.1.0/24`:
1. `10.0.1.0`: Network Address.
2. `10.0.1.1`: Reserved by AWS for the **VPC Router**.
3. `10.0.1.2`: Reserved by AWS for the **VPC DNS Server** (AmazonProvidedDNS / Route 53 Resolver).
4. `10.0.1.3`: Reserved by AWS for future use.
5. `10.0.1.255`: Network Broadcast Address (AWS does not support broadcast, but reserves it).
- **Usable IPs**: $256 - 5 = \mathbf{251}$ usable addresses!

---

## 3. Public vs. Private Subnets

What makes a subnet "Public" vs "Private"?
- A subnet is **NOT** intrinsically public or private by name.
- It becomes **Public** if its Route Table has a route directing default internet traffic (`0.0.0.0/0`) to an **Internet Gateway (IGW)**.
- It is **Private** if its Route Table does **NOT** route to an IGW. To download updates or call external APIs, private instances route through a **NAT Gateway** located in a public subnet!

```
+-----------------------------------------------------------------------------------------+
|                                    VPC: 10.0.0.0/16                                     |
|                                                                                         |
|  +-------------------------------------+   +-----------------------------------------+  |
|  |     Public Subnet (10.0.1.0/24)     |   |       Private Subnet (10.0.10.0/24)     |  |
|  |     [ NAT Gateway: 10.0.1.50 ]      |   |       [ App EC2 Instance: 10.0.10.15 ]  |  |
|  |     Route: 0.0.0.0/0 -> igw-xxx     |   |       Route: 0.0.0.0/0 -> nat-xxx       |  |
|  +-------------------------------------+   +-----------------------------------------+  |
|                   |                                             |                       |
+-------------------|---------------------------------------------|-----------------------+
                    v                                             |
         [ Internet Gateway (IGW) ] <-----------------------------+ (via NAT Gateway)
                    |
                    v
              [ INTERNET ]
```

---

## 4. Hands-on Lab: VPC Creation via AWS CLI

```bash
# 1. Create VPC with DNS hostnames enabled
VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query "Vpc.VpcId" --output text)
aws ec2 modify-vpc-attribute --vpc-id "$VPC_ID" --enable-dns-hostnames '{"Value": true}'
aws ec2 create-tags --resources "$VPC_ID" --tags Key=Name,Value=production-vpc

# 2. Create Public Subnet in Availability Zone A
PUBLIC_SUBNET_ID=$(aws ec2 create-subnet \
  --vpc-id "$VPC_ID" \
  --cidr-block 10.0.1.0/24 \
  --availability-zone ap-south-1a \
  --query "Subnet.SubnetId" --output text)
aws ec2 create-tags --resources "$PUBLIC_SUBNET_ID" --tags Key=Name,Value=prod-public-1a

# 3. Create Private Subnet in Availability Zone A
PRIVATE_SUBNET_ID=$(aws ec2 create-subnet \
  --vpc-id "$VPC_ID" \
  --cidr-block 10.0.10.0/24 \
  --availability-zone ap-south-1a \
  --query "Subnet.SubnetId" --output text)
aws ec2 create-tags --resources "$PRIVATE_SUBNET_ID" --tags Key=Name,Value=prod-private-1a
```

---

## 5. Interview & Review Questions
1. **If a subnet has a CIDR of `/28`, how many usable IP addresses are available for EC2 instances?**
   - *Answer*: A `/28` subnet has $2^{(32-28)} = 2^4 = 16$ total IP addresses. Since AWS reserves 5 IP addresses in every subnet, exactly **11 usable IP addresses** ($16 - 5$) are available.
2. **Can a single AWS Subnet span multiple Availability Zones?**
   - *Answer*: No. A VPC spans all Availability Zones in a Region, but an individual Subnet is strictly tied to a single Availability Zone. To build a multi-AZ fault-tolerant architecture, you must create distinct subnets in separate AZs.
