# Day 59: Reusable Terraform Modules & Multi-Environment Architecture

## 1. Theoretical Foundation

### What is a Terraform Module?
A **Module** is a container for multiple resources that are used together.
- **Root Module**: The primary working directory where `terraform apply` is executed.
- **Child Module**: A reusable, parameterized package of Terraform code called by the root module.

### Why Modularize?
Instead of copying 200 lines of VPC code into `environments/dev`, `environments/stage`, and `environments/prod`, you write a single, standardized, hardened `modules/vpc` module once, and instantiate it with different input parameters!

---

## 2. Directory Layout: Enterprise Standard Structure

```text
terraform-infrastructure/
├── modules/
│   ├── vpc/
│   │   ├── main.tf           # VPC, Subnet, IGW, NAT resources
│   │   ├── variables.tf      # Configurable inputs (cidr, az_list)
│   │   └── outputs.tf        # Exported attributes (vpc_id, subnet_ids)
│   └── ec2_cluster/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── environments/
    ├── dev/
    │   ├── backend.tf        # S3 key: env/dev/terraform.tfstate
    │   ├── main.tf           # Instantiates modules with dev sizing
    │   └── terraform.tfvars  # environment = "dev", instance_type = "t4g.small"
    ├── stage/
    │   ├── backend.tf
    │   ├── main.tf
    │   └── terraform.tfvars
    └── prod/
        ├── backend.tf        # S3 key: env/prod/terraform.tfstate
        ├── main.tf           # Instantiates modules with prod HA sizing
        └── terraform.tfvars  # environment = "prod", multi_az = true
```

---

## 3. Creating a Reusable Child Module (`modules/vpc`)

`modules/vpc/variables.tf`:
```hcl
variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "List of public subnet CIDR blocks"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of target availability zones"
}

variable "environment" {
  type        = string
  description = "Deployment environment"
}
```

`modules/vpc/main.tf`:
```hcl
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.environment}-vpc"
    Environment = var.environment
  }
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.environment}-public-${var.availability_zones[count.index]}"
    Environment = var.environment
  }
}
```

`modules/vpc/outputs.tf`:
```hcl
output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}
```

---

## 4. Instantiating the Module in `environments/prod/main.tf`

```hcl
module "production_vpc" {
  source = "../../modules/vpc" # Local path (or Git repo: "git::https://github.com/org/tf-modules.git//vpc?ref=v1.2.0")

  vpc_cidr             = "10.100.0.0/16"
  public_subnet_cidrs  = ["10.100.1.0/24", "10.100.2.0/24"]
  availability_zones   = ["ap-south-1a", "ap-south-1b"]
  environment          = "production"
}

# Consuming the module's output in another module or resource:
module "app_cluster" {
  source    = "../../modules/ec2_cluster"
  vpc_id    = module.production_vpc.vpc_id
  subnet_id = module.production_vpc.public_subnet_ids[0]
}
```

---

## 5. Workspaces vs. Separate Environment Directories

Terraform offers **Workspaces** (`terraform workspace new dev/prod`):
- Workspaces share the exact same configuration directory and simply swap state files.
- **Enterprise Consensus**: **Avoid Workspaces for Dev/Prod separation!** A single accidental CLI command (`terraform destroy`) in the wrong workspace can destroy production.
- **Industry Standard**: Use separate directory trees (`environments/dev` vs `environments/prod`) with separate remote state keys and isolated IAM credentials.

---

## 6. Interview & Review Questions
1. **Why do production engineering teams prefer separate directory structures over Terraform Workspaces for multi-environment deployments?**
   - *Answer*: Separate directory structures provide hard blast-radius isolation, distinct remote backend state paths, environment-specific provider credentials, and different version pins. Workspaces share the same root configuration and variables, making accidental production destruction far more likely due to a missed CLI context switch.
2. **What is the syntax to pin a Terraform module sourced from a remote Git repository to a specific release tag?**
   - *Answer*: Append `?ref=<tag>` to the source URL: `source = "git::https://github.com/my-org/terraform-modules.git//modules/vpc?ref=v2.1.0"`.
