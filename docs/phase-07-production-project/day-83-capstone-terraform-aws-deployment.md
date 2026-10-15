# Day 83: Capstone Infrastructure — Terraform Multi-AZ AWS Deployment

## 1. Architectural Blueprint

This Terraform suite provisions the complete underlying AWS cloud foundation:
1. **Multi-AZ VPC** with 2 Public Subnets, 2 Private App Subnets, and 2 Private Database Subnets.
2. **Internet Gateway & 2 NAT Gateways** (one per AZ).
3. **AWS Managed EKS Kubernetes Cluster** with managed Graviton node groups.
4. **Amazon RDS PostgreSQL** Multi-AZ database instance with automated daily snapshots.
5. **Security Groups** enforcing strict tiering (ALB -> EKS -> RDS).

---

## 2. Terraform Code Implementation

### `main.tf`
```hcl
terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }
  }

  backend "s3" {
    bucket         = "cloudorders-tfstate-prod"
    key            = "capstone/prod/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = "CloudOrders"
      Environment = "Production"
      ManagedBy   = "Terraform"
    }
  }
}

# 1. VPC Module
module "vpc" {
  source = "./modules/vpc"

  cidr_block       = "10.0.0.0/16"
  azs              = ["ap-south-1a", "ap-south-1b"]
  public_subnets   = ["10.0.1.0/24", "10.0.2.0/24"]
  app_subnets      = ["10.0.10.0/24", "10.0.20.0/24"]
  db_subnets       = ["10.0.100.0/24", "10.0.200.0/24"]
  enable_nat_gw    = true
  single_nat_gw    = false # Multi-AZ High Availability
}

# 2. RDS PostgreSQL Multi-AZ
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "cloudorders-db-subnet-group"
  subnet_ids = module.vpc.db_subnet_ids
}

resource "aws_security_group" "db_sg" {
  name        = "cloudorders-db-sg"
  description = "Allow inbound postgres from EKS nodes only"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "postgres" {
  identifier             = "cloudorders-prod-db"
  allocated_storage      = 100
  max_allocated_storage  = 500 # Auto-scales disk up to 500GB!
  storage_type           = "gp3"
  engine                 = "postgres"
  engine_version         = "16.1"
  instance_class         = "db.t4g.medium"
  multi_az               = true
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  username               = "dbadmin"
  password               = var.db_master_password
  skip_final_snapshot    = false
  final_snapshot_identifier = "cloudorders-prod-db-final-snapshot"
  deletion_protection    = true
}
```

---

## 3. Provisioning Workflow

```bash
# Initialize and validate
terraform init
terraform validate

# Plan and export binary execution plan
terraform plan -out=tfplan

# Apply execution plan to AWS
terraform apply tfplan
```

---

## 4. Key Takeaways & Review
- Uses `multi_az = true` on RDS to guarantee $RPO = 0$ via synchronous cross-AZ replication.
- Implements `max_allocated_storage = 500` to automatically prevent database storage exhaustion outages.
- Database security group accepts ingress connections **only** from the EKS worker nodes security group!
