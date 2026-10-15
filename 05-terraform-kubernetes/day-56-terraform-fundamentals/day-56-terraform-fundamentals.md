# Day 56: Terraform Fundamentals, HCL Syntax & Lifecycle Workflow

## 1. Theoretical Foundation

### What is Infrastructure as Code (IaC)?
Infrastructure as Code (IaC) is the practice of managing and provisioning computing infrastructure through human-readable, machine-parsable definition files, rather than through physical hardware configuration or interactive web consoles.

### Declarative vs. Imperative IaC
- **Imperative (e.g. Bash, AWS CLI, Python boto3)**: Defines **HOW** to reach the goal step-by-step (`create VPC, wait 5s, create subnet, create route table`). Prone to race conditions and non-idempotency.
- **Declarative (e.g. Terraform, Kubernetes YAML)**: Defines **WHAT** the desired end-state should be (`I need 1 VPC with CIDR 10.0.0.0/16 and 2 subnets`). The engine figures out the dependency graph, discovers what already exists, and performs the minimal mutations to reach the target state.

---

## 2. Core Terraform Workflow & Commands

```
[ main.tf (Code) ]
        |
        v
[ 1. terraform init ]    ---> Downloads cloud provider plugins (e.g. hashicorp/aws) into .terraform/
        |
        v
[ 2. terraform plan ]    ---> Compares Desired Code vs State vs Reality; outputs execution plan (+, ~, -)
        |
        v
[ 3. terraform apply ]   ---> Calls Cloud Provider APIs to provision resources; updates terraform.tfstate
        |
        v
[ 4. terraform destroy ] ---> Gracefully terminates and purges all managed infrastructure
```

### Essential CLI Commands
```bash
# Initialize working directory, download providers and configure backend
terraform init

# Check code formatting according to canonical style rules
terraform fmt -check
terraform fmt -recursive

# Validate HCL syntax and internal consistency without making cloud calls
terraform validate

# Generate and review execution plan
terraform plan -out=tfplan

# Apply execution plan idempotently
terraform apply tfplan

# Destroy all managed resources
terraform destroy -auto-approve
```

---

## 3. HashiCorp Configuration Language (HCL) Syntax

A typical Terraform configuration consists of **Providers** and **Resources**:

`main.tf`:
```hcl
terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
  default_tags {
    tags = {
      Environment = "Production"
      ManagedBy   = "Terraform"
    }
  }
}

# Define a resource: resource "TYPE" "LOCAL_NAME"
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "production-vpc"
  }
}

resource "aws_subnet" "public_1a" {
  vpc_id                  = aws_vpc.main.id # Implicit dependency reference!
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-1a"
  }
}
```

---

## 4. Resource Dependency Graph

Terraform automatically builds a Directed Acyclic Graph (DAG) of your infrastructure:
- **Implicit Dependencies**: In the example above, `aws_subnet.public_1a` references `aws_vpc.main.id`. Terraform automatically infers that the VPC must be created **before** the Subnet!
- **Explicit Dependencies (`depends_on`)**: Used only when dependencies exist outside of direct attribute references (e.g. an EC2 instance depends on an S3 bucket populated by a separate process).

---

## 5. Interview & Review Questions
1. **Explain the difference between `terraform plan` and `terraform apply`.**
   - *Answer*: `terraform plan` is a read-only command that performs a delta comparison between your declarative HCL code, the stored state file, and the live cloud infrastructure. It outputs a proposed execution plan showing what will be created (`+`), modified (`~`), or destroyed (`-`). `terraform apply` executes the API mutations to realize the plan and updates the state file.
2. **What does the `~>` (tilde-greater-than) version constraint operator mean in provider blocks?**
   - *Answer*: The pessimistic constraint operator `~> 5.40` allows right-most patch and minor version upgrades within the same minor release family (e.g. `>= 5.40.0` and `< 6.0.0`), preventing breaking major version upgrades from disrupting infrastructure code.
