# Day 40: AWS Mini-Project — Enterprise Multi-AZ 2-Tier VPC Architecture

## 1. Project Architecture & Objectives

In this Phase 3 capstone mini-project, you will design and deploy a complete production-ready, highly available **Two-Tier AWS Virtual Private Cloud (VPC)** architecture spanning two Availability Zones.

### Architectural Diagram
```
Region: ap-south-1 (Mumbai)
VPC: 10.0.0.0/16
+---------------------------------------------------------------------------------------------------+
|  [ Internet Gateway (IGW) ]                                                                       |
|         |                                                                                         |
|  +------|---------------------------------------+  +--------------------------------------------+ |
|  |  Availability Zone A (ap-south-1a)           |  |  Availability Zone B (ap-south-1b)         | |
|  |                                              |  |                                            | |
|  |  [ Public Subnet A: 10.0.1.0/24 ]            |  |  [ Public Subnet B: 10.0.2.0/24 ]          | |
|  |  - Public ALB / Bastion                      |  |  - Public ALB                              | |
|  |  - NAT Gateway A (EIP 1)                     |  |  - (Optional NAT Gateway B)                | |
|  |  - Route: 0.0.0.0/0 -> IGW                   |  |  - Route: 0.0.0.0/0 -> IGW                 | |
|  +----------------------------------------------+  +--------------------------------------------+ |
|                         ^                                                 ^                       |
|                         |                                                 |                       |
|  +----------------------|-----------------------+  +----------------------|---------------------+ |
|  |  [ Private App Subnet A: 10.0.10.0/24 ]      |  |  [ Private App Subnet B: 10.0.20.0/24 ]    | |
|  |  - EC2 App Instance (No Public IP)           |  |  - EC2 App Instance (No Public IP)         | |
|  |  - SG: Allows 8080 from ALB-SG               |  |  - SG: Allows 8080 from ALB-SG             | |
|  |  - Route: 0.0.0.0/0 -> NAT-GW-A              |  |  - Route: 0.0.0.0/0 -> NAT-GW-A            | |
|  +----------------------------------------------+  +--------------------------------------------+ |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. Step-by-Step CLI Deployment Guide

### Step 1: Create the VPC
```bash
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=prod-vpc},{Key=Environment,Value=Production}]' \
  --query "Vpc.VpcId" --output text)

aws ec2 modify-vpc-attribute --vpc-id "$VPC_ID" --enable-dns-hostnames '{"Value": true}'
echo "Created VPC: $VPC_ID"
```

### Step 2: Create and Attach the Internet Gateway
```bash
IGW_ID=$(aws ec2 create-internet-gateway \
  --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=prod-igw}]' \
  --query "InternetGateway.InternetGatewayId" --output text)

aws ec2 attach-internet-gateway --vpc-id "$VPC_ID" --internet-gateway-id "$IGW_ID"
echo "Attached IGW: $IGW_ID"
```

### Step 3: Create Subnets Across 2 Availability Zones
```bash
# Public Subnets (Tier 1)
PUB_SUB_A=$(aws ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block 10.0.1.0/24 --availability-zone ap-south-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=prod-public-1a}]' --query "Subnet.SubnetId" --output text)

PUB_SUB_B=$(aws ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block 10.0.2.0/24 --availability-zone ap-south-1b \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=prod-public-1b}]' --query "Subnet.SubnetId" --output text)

# Private App Subnets (Tier 2)
PRIV_SUB_A=$(aws ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block 10.0.10.0/24 --availability-zone ap-south-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=prod-private-1a}]' --query "Subnet.SubnetId" --output text)

PRIV_SUB_B=$(aws ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block 10.0.20.0/24 --availability-zone ap-south-1b \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=prod-private-1b}]' --query "Subnet.SubnetId" --output text)
```

### Step 4: Configure Public Routing
```bash
# Create Public Route Table
PUB_RT=$(aws ec2 create-route-table --vpc-id "$VPC_ID" \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=prod-public-rt}]' --query "RouteTable.RouteTableId" --output text)

# Default route to Internet Gateway
aws ec2 create-route --route-table-id "$PUB_RT" --destination-cidr-block 0.0.0.0/0 --gateway-id "$IGW_ID"

# Associate Public Subnets with Public Route Table
aws ec2 associate-route-table --subnet-id "$PUB_SUB_A" --route-table-id "$PUB_RT"
aws ec2 associate-route-table --subnet-id "$PUB_SUB_B" --route-table-id "$PUB_RT"
```

### Step 5: Provision NAT Gateway for Private Egress
```bash
# Allocate Elastic IP for NAT Gateway
EIP_ALLOC=$(aws ec2 allocate-address --domain vpc \
  --tag-specifications 'ResourceType=elastic-ip,Tags=[{Key=Name,Value=prod-nat-eip}]' --query "AllocationId" --output text)

# Deploy NAT Gateway in Public Subnet A
NAT_GW=$(aws ec2 create-nat-gateway --subnet-id "$PUB_SUB_A" --allocation-id "$EIP_ALLOC" \
  --tag-specifications 'ResourceType=natgateway,Tags=[{Key=Name,Value=prod-nat-gw}]' --query "NatGateway.NatGatewayId" --output text)

echo "Waiting for NAT Gateway $NAT_GW to become available..."
aws ec2 wait nat-gateway-available --nat-gateway-ids "$NAT_GW"
```

### Step 6: Configure Private Routing
```bash
# Create Private Route Table
PRIV_RT=$(aws ec2 create-route-table --vpc-id "$VPC_ID" \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=prod-private-rt}]' --query "RouteTable.RouteTableId" --output text)

# Route outbound internet traffic from private subnets to the NAT Gateway
aws ec2 create-route --route-table-id "$PRIV_RT" --destination-cidr-block 0.0.0.0/0 --nat-gateway-id "$NAT_GW"

# Associate Private Subnets
aws ec2 associate-route-table --subnet-id "$PRIV_SUB_A" --route-table-id "$PRIV_RT"
aws ec2 associate-route-table --subnet-id "$PRIV_SUB_B" --route-table-id "$PRIV_RT"
```

---

## 3. Security Group Defense Configuration

```bash
# 1. ALB Security Group (Public facing)
ALB_SG=$(aws ec2 create-security-group --group-name "prod-alb-sg" --description "Public HTTPS ingress" --vpc-id "$VPC_ID" --query "GroupId" --output text)
aws ec2 authorize-security-group-ingress --group-id "$ALB_SG" --protocol tcp --port 443 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id "$ALB_SG" --protocol tcp --port 80 --cidr 0.0.0.0/0

# 2. App Security Group (Private facing: ONLY allows traffic from ALB Security Group)
APP_SG=$(aws ec2 create-security-group --group-name "prod-app-sg" --description "Private app ingress" --vpc-id "$VPC_ID" --query "GroupId" --output text)
aws ec2 authorize-security-group-ingress --group-id "$APP_SG" --protocol tcp --port 8080 --source-group "$ALB_SG"
```

---

## 4. Phase 3 Milestone Completed!

🎉 **Congratulations! You have mastered Phase 3: AWS Cloud Engineering.**
You now possess enterprise-grade expertise in:
- AWS Global infrastructure and the Shared Responsibility model.
- IAM least-privilege policies, roles, and temporary STS credentials.
- Amazon EC2 compute sizing, lifecycle, user-data bootstrap automation, and status triage.
- Amazon EBS block storage types (gp3/io2), snapshots, and AMIs.
- Amazon S3 object storage tiers, bucket security policies, Block Public Access, and CloudFront OAC.
- Amazon VPC network design, CIDR calculations, route tables, IGWs, and NAT Gateways.
- Stateful Security Groups vs stateless NACLs.
- CloudWatch metrics, alarms, and logs insights telemetry.
- FinOps cost optimization and tagging governance.

Next: **Phase 4 — Containers & CI/CD (Docker, Jenkins, GitHub Actions) (Days 41–55)**!
